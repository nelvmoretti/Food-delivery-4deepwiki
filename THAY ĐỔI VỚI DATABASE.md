# Food-delivery

## Ghi chú về Lược đồ Cơ sở dữ liệu (Database Schema Notes)

### 1. Quan hệ 1:1 Mandatory giữa Đơn hàng (DON_HANG) và Thanh toán (THANH_TOAN)

Dựa trên lược đồ yêu cầu quan hệ **1:1 Mandatory (Total Participation)** từ cả hai phía, hiện trạng và kế hoạch sửa đổi như sau:

#### Hiện trạng (Cần sửa):
- **Tính duy nhất (1:1):** Cột `ID_thanh_toan` trong `DON_HANG` chưa có ràng buộc `UNIQUE`. Điều này cho phép nhiều đơn hàng trỏ về cùng một thanh toán (N:1).
- **Tính bắt buộc (Mandatory):** Cột `ID_thanh_toan` đang cho phép `NULL`. Điều này vi phạm tính bắt buộc của đơn hàng phải có thanh toán ngay khi tạo.
- **Phía Thanh toán:** Chưa có cơ chế ràng buộc cứng ở mức schema để đảm bảo một bản ghi `THANH_TOAN` phải luôn gắn liền với một `DON_HANG`.

#### Giải pháp triển khai (Sẽ thực hiện):
Để triển khai đúng theo lược đồ mà không dùng Trigger, cần thực hiện:

1.  **Chỉnh sửa bảng `DON_HANG` trong `01_create_tables.sql`:**
    - Thêm `NOT NULL` cho cột `ID_thanh_toan`.
    - Thêm ràng buộc `UNIQUE` cho cột `ID_thanh_toan`.
    - Cú pháp dự kiến:
      ```sql
      ID_thanh_toan INT NOT NULL UNIQUE,
      CONSTRAINT FK_DH_ThanhToan FOREIGN KEY (ID_thanh_toan) REFERENCES THANH_TOAN(ID)
      ```

2.  **Ràng buộc vòng đời (Lifecycle):**
    - Đảm bảo trong mã nguồn ứng dụng (backend) hoặc Store Procedure, việc tạo `THANH_TOAN` và `DON_HANG` phải nằm trong cùng một **Transaction** để đảm bảo tính nguyên tử (Atomic).

3.  **Lưu ý về thứ tự khởi tạo:**
    - Vì `DON_HANG` giữ khóa ngoại trỏ đến `THANH_TOAN`, bản ghi `THANH_TOAN` phải được tạo trước để lấy `ID`, sau đó mới `INSERT` vào `DON_HANG`.

### 2. Quan hệ 1:1 Mandatory giữa Khách hàng (KHACH_HANG) và Giỏ hàng (GIO_HANG)

Tương tự quan hệ Đơn hàng - Thanh toán, quan hệ này cần được siết chặt để đảm bảo mỗi khách hàng có duy nhất một giỏ hàng và ngược lại.

#### Hiện trạng (Cần sửa):
- **Tính duy nhất (1:1):** `ID_khach_hang` trong `GIO_HANG` thiếu ràng buộc `UNIQUE`.
- **Tính bắt buộc (Mandatory):** 
    - Phía Giỏ hàng đã có `NOT NULL` (Mandatory).
    - Phía Khách hàng chưa có ràng buộc để đảm bảo luôn tồn tại một Giỏ hàng đi kèm.

#### Giải pháp triển khai:
1.  **Chỉnh sửa bảng `GIO_HANG` trong `01_create_tables.sql`:**
    - Thêm ràng buộc `UNIQUE` cho cột `ID_khach_hang`.
    - Cú pháp dự kiến:
      ```sql
      ID_khach_hang INT NOT NULL UNIQUE,
      ```
2.  **Khởi tạo đồng bộ:**
    - Cần đảm bảo khi một người dùng đăng ký với phân loại là `Khach_hang`, hệ thống phải tự động khởi tạo một bản ghi `GIO_HANG` tương ứng cho họ trong cùng một Transaction.

### 3. Phân lớp Người dùng (Specialization/Generalization)

Mối quan hệ giữa `TAI_KHOAN_NGUOI_DUNG` (Cha) và `KHACH_HANG`, `NHAN_VIEN`, `TAI_XE` (Con).

#### Hiện trạng (SAI so với lược đồ Overlap):
- **Tính chất hiện tại:** Đang là **Disjoint** (do dùng 1 cột phân loại duy nhất).
- **Vấn đề:** Không cho phép một tài khoản đóng nhiều vai trò (ví dụ: vừa là tài xế vừa là khách hàng).

#### Giải pháp sửa đổi để đúng với Overlap (o):
1.  **Chỉnh sửa bảng `TAI_KHOAN_NGUOI_DUNG`:**
    - Loại bỏ cột `Phan_loai_nguoi_dung` và ràng buộc `CK_TKND_PhanLoai`.
    - Thêm 3 cột cờ kiểu `BIT`: `is_khach`, `is_nhanvien`, `is_taixe`.
    - Thêm ràng buộc Check đảm bảo ít nhất 1 vai trò:
      ```sql
      CONSTRAINT CK_TKND_Role CHECK (is_khach=1 OR is_nhanvien=1 OR is_taixe=1)
      ```
2.  **Logic nghiệp vụ:**
    - Một ID có thể xuất hiện đồng thời trong cả 3 bảng con `KHACH_HANG`, `NHAN_VIEN`, `TAI_XE`.

### 4. Các quan hệ 1:N và N:1

#### 4.1 Món ăn - Chi tiết đơn hàng (1:N, chi tiết đơn hàng là mandatory)
* **Yêu cầu:** 1 Món ăn có nhiều Chi tiết đơn hàng. Chi tiết đơn hàng bắt buộc phải thuộc về 1 Món ăn.
* **Đánh giá triển khai:** ✅ **ĐÚNG**
* **Chi tiết:** Trong bảng `CHI_TIET_DON_HANG`, cột `ID_mon_an INT NOT NULL` được sử dụng. Ràng buộc `NOT NULL` đảm bảo rằng không thể có một Chi tiết đơn hàng nào tồn tại mà không gắn với một Món ăn. Món ăn là optional (1 món ăn có thể chưa có ai đặt).

#### 4.2 Món ăn - Nhà hàng (N:1, cả hai đều là mandatory)
* **Yêu cầu:** Món ăn bắt buộc phải có Nhà hàng. Nhà hàng bắt buộc phải có ít nhất 1 Món ăn.
* **Đánh giá triển khai:** ⚠️ **CHỈ ĐÚNG MỘT NỬA**
* **Chi tiết:** 
  * **Chiều Món ăn -> Nhà hàng (Mandatory):** ✅ Đã đúng. Bảng `MON_AN` có cột `ID_nha_hang INT NOT NULL`.
  * **Chiều Nhà hàng -> Món ăn (Mandatory):** ❌ **Chưa triển khai**. Hiện tại hoàn toàn có thể `INSERT` một `NHA_HANG` mới mà không cần thêm `MON_AN` nào, vì không có Trigger chặn việc tạo nhà hàng rỗng. 
  * *Cách khắc phục:* Áp dụng mandatory tuyệt đối ở chiều này trong SQL Server rất khó mà không dùng Trigger. Trong thực tế, người ta thường xử lý việc này ở tầng Application (Backend) hoặc cho phép Nhà hàng rỗng lúc khởi tạo, sau đó mới thêm món.

#### 4.3 Nhà hàng - Đơn hàng (1:N, đơn hàng là mandatory)
* **Yêu cầu:** 1 Nhà hàng có nhiều Đơn hàng. Đơn hàng bắt buộc phải thuộc về 1 Nhà hàng.
* **Đánh giá triển khai:** ✅ **ĐÚNG**
* **Chi tiết:** Trong bảng `DON_HANG`, cột `ID_nha_hang INT NOT NULL` đảm bảo mỗi đơn hàng sinh ra đều phải xác định rõ nó thuộc về nhà hàng nào. Nhà hàng là optional (nhà hàng có thể chưa có đơn hàng).

#### 4.4 Đơn hàng - Tài xế (N:1, cả hai là mandatory)
* **Yêu cầu:** 1 Tài xế nhận nhiều Đơn hàng, 1 Đơn hàng chỉ có 1 Tài xế. Đơn hàng phải có tài xế, và Tài xế phải có đơn hàng.
* **Đánh giá triển khai:** ❌ **SAI LỆCH NHIỀU**
* **Chi tiết:**
  1. **Sai bản số (N:M thay vì N:1):** Đang dùng bảng trung gian `TAI_XE_NHAN_DON` với Khóa chính là `(ID_don_hang, ID_tai_xe)`. Thiết kế này cho phép 1 Đơn hàng được nhận bởi **nhiều** Tài xế (trở thành quan hệ N:M).
     * *Cách sửa:* Nếu là N:1 (1 đơn chỉ 1 tài xế), bạn nên biến `ID_don_hang` thành `PRIMARY KEY` trong bảng `TAI_XE_NHAN_DON`, hoặc chuyển luôn cột `ID_tai_xe` vào bảng `DON_HANG`.
  2. **Sai tính bắt buộc (Mandatory):** Hiện tại `DON_HANG` hoàn toàn có thể tồn tại mà không nằm trong bảng `TAI_XE_NHAN_DON` (ví dụ lúc trạng thái là `Cho_xac_nhan`). Đồng thời Tài xế tạo ra cũng có thể ở trạng thái `Offline` mà không có đơn hàng nào. Việc "cả hai đều mandatory" đi ngược lại logic nghiệp vụ thực tế (Đơn hàng cần thời gian chờ tài xế nhận).

#### 4.5 Nhân viên - Món ăn (1:N, nhân viên là mandatory)
* **Yêu cầu:** 1 Nhân viên quản lý/duyệt nhiều Món ăn. Mỗi Món ăn bắt buộc phải có 1 Nhân viên quản lý.
* **Đánh giá triển khai:** ❌ **CHƯA ĐÚNG**
* **Chi tiết:** Trong bảng `MON_AN`, đang khai báo `ID_nguoi_duyet INT` (cho phép `NULL`). Hệ thống đang hiểu là Món ăn có thể không có nhân viên duyệt (Nhân viên là optional). 
  * *Cách sửa:* Cần đổi thành `ID_nguoi_duyet INT NOT NULL`.

> **💡 Giải thích: Tại sao Món ăn KHÔNG CẦN là mandatory (tức là Món ăn là Optional đối với Nhân viên)?**
> Việc Món ăn là **Optional** đối với Nhân viên (1 Nhân viên có thể quản lý 0 món ăn) là hoàn toàn hợp lý vì:
> 1. **Logic phân quyền / Vai trò:** Không phải nhân viên nào cũng làm công việc kiểm duyệt thực đơn (VD: Kế toán, Chăm sóc khách hàng không gắn với bất kỳ món ăn nào).
> 2. **Logic vòng đời (Lifecycle):** Khi một nhân viên mới tinh vừa được tuyển dụng, họ chưa thể được giao việc ngay. Nếu bắt buộc Nhân viên phải có ít nhất 1 Món ăn, bạn sẽ không thể tạo tài khoản cho họ nếu chưa có sẵn món ăn nào để gán.

#### 4.6 Khách hàng - Đơn hàng (1:N, cả hai đều là optional)
* **Yêu cầu:** Khách hàng không bắt buộc phải có đơn, và Đơn hàng cũng không bắt buộc phải có Khách hàng.
* **Đánh giá triển khai:** ❌ **CHƯA ĐÚNG**
* **Chi tiết:** Trong bảng `DON_HANG`, cột `ID_khach_hang INT NOT NULL`. Ràng buộc `NOT NULL` ép buộc Đơn hàng **luôn phải xác định danh tính Khách hàng** (Tức là Khách hàng đang là Mandatory đối với Đơn hàng).
  * *Cách sửa:* Nếu ý bạn cho phép khách vãng lai (Guest) đặt hàng không cần tài khoản, bạn phải sửa lại thành `ID_khach_hang INT NULL`.

### 5. Các quan hệ N:N

#### 5.1 Khách hàng - Món ăn (N:N, optional cả hai)
* **Ý nghĩa:** Khách hàng có thể đánh giá nhiều món ăn, món ăn có thể được đánh giá bởi nhiều khách hàng. Không bắt buộc phải có đánh giá.
* **Đánh giá triển khai:** ✅ **ĐÚNG**
* **Chi tiết:** Được thể hiện qua bảng `DANH_GIA` với khóa chính `(ID_khach_hang, ID_mon_an)`. Việc cả hai đều optional là tính chất tự nhiên mặc định của bảng trung gian trong SQL (do không có trigger ép buộc insert). Triển khai này hoàn toàn phù hợp.

#### 5.2 Khuyến mãi - Món ăn (N:N, optional cả hai)
* **Ý nghĩa:** Một khuyến mãi áp dụng cho nhiều món ăn, một món ăn có thể có nhiều khuyến mãi. Không bắt buộc phải áp dụng khuyến mãi.
* **Đánh giá triển khai:** ✅ **ĐÚNG**
* **Chi tiết:** Thể hiện qua bảng `KHUYEN_MAI_CHO_MON_AN` với khóa chính `(ID_mon_an, ID_khuyen_mai)`. Bảng trung gian này mặc định là optional cho cả 2 phía.

#### 5.3 Món ăn - Giỏ hàng (N:N, optional cả hai)
* **Ý nghĩa:** Giỏ hàng chứa nhiều món ăn, món ăn nằm trong nhiều giỏ hàng. Không bắt buộc.
* **Đánh giá triển khai:** ✅ **ĐÚNG**
* **Chi tiết:** Thể hiện qua bảng `MON_AN_TRONG_GIO_HANG` với khóa chính `(ID_gio_hang, ID_mon_an)`. 

### 6. Thuộc tính đa trị và Dẫn xuất

#### 6.1 Thuộc tính đa trị: Số điện thoại (của người dùng)
* **Đánh giá triển khai:** ✅ **ĐÚNG VỀ MẶT CẤU TRÚC**
* **Chi tiết:** Bạn đã tách riêng bảng `SO_DIEN_THOAI` với `SDT_chinh` làm Khóa chính và `id_nguoi_dung` làm Khóa ngoại. Điều này cho phép 1 người dùng có nhiều số điện thoại, đúng chuẩn thiết kế cho thuộc tính đa trị.
* **Cần sửa:** Tên cột `SDT_chinh` dễ gây hiểu lầm là chỉ có 1 số chính. Nên đổi tên cột thành `SDT` (Số điện thoại). Đồng thời, nếu muốn bắt buộc người dùng khi đăng ký phải có ít nhất 1 SĐT, bạn cần cài đặt Application Logic hoặc dùng Trigger (vì hiện tại tạo Khách hàng không cần tạo SĐT vẫn được).

#### 6.2 Thuộc tính dẫn xuất: Doanh thu (Nhà hàng)
* **Đánh giá triển khai:** ✅ **ĐÚNG**
* **Chi tiết:** Đã có cột `Doanh_thu` trong bảng `NHA_HANG`. Trong file `04_triggers.sql`, bạn đã viết trigger `trg_UpdateDoanhThuNhaHang` để tự động tính `SUM(Tong_tien)` của các đơn hàng có trạng thái `Da_giao`. Triển khai này chuẩn xác.

#### 6.3 Thuộc tính dẫn xuất: Tổng tiền (Đơn hàng)
* **Đánh giá triển khai:** ✅ **ĐÚNG**
* **Chi tiết:** Có cột `Tong_tien` trong bảng `DON_HANG`. Trigger `trg_UpdateTongTienDonHang` đã được tạo để tính `SUM(So_luong * Gia_chot)` từ `CHI_TIET_DON_HANG`. 

#### 6.4 Thuộc tính dẫn xuất: Giá chốt (Chi tiết đơn hàng)
* **Đánh giá triển khai:** ❌ **CHƯA HOÀN THIỆN**
* **Chi tiết:** Bảng `CHI_TIET_DON_HANG` có cột `Gia_chot DECIMAL(18,2) NOT NULL`. Về bản chất, `Gia_chot` thường được dẫn xuất từ `MON_AN.Gia` (trừ đi số tiền giảm giá nếu món ăn có áp dụng từ `KHUYEN_MAI_CHO_MON_AN`). Tuy nhiên, hiện tại **không có Trigger** nào tự động điền giá trị cho `Gia_chot` khi Insert/Update vào `CHI_TIET_DON_HANG`.
* **Cách khắc phục:** 
  1. Cần bổ sung 1 Trigger `AFTER INSERT, UPDATE` trên `CHI_TIET_DON_HANG`.
  2. Logic trigger sẽ tự động lấy `MON_AN.Gia` từ bảng `MON_AN`, sau đó kiểm tra xem món ăn này có đang được hưởng khuyến mãi nào còn hạn không.
  3. Tính ra giá trị thực tế và cập nhật lại vào cột `Gia_chot`. 
  *(Lưu ý: Bạn phải thiết kế sao cho tính được `Gia_chot` TRƯỚC, rồi Trigger `trg_UpdateTongTienDonHang` mới lấy `Gia_chot` để tính `Tổng tiền`. Thứ tự thực thi Trigger rất quan trọng).*
