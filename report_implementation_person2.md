# Báo Cáo Hiện Thực — Person 2: Sample Data & CRUD Procedures

## 1. Tổng Quan Nhiệm Vụ

Person 2 phụ trách 2 file SQL:

| File | Nội dung | Điểm |
|------|---------|------|
| `02_sample_data.sql` | Dữ liệu mẫu ≥5 dòng/bảng cho 17 bảng | 1 điểm |
| `03_procedures_crud.sql` | 3 thủ tục CRUD cho bảng `MON_AN` | 1 điểm |

---

## 2. File `02_sample_data.sql` — Dữ Liệu Mẫu

### 2.1. Tóm tắt dữ liệu

| # | Bảng | Số dòng | Ghi chú |
|---|------|---------|---------|
| 1 | NHA_HANG | 5 | 5 nhà hàng Việt Nam thực tế |
| 2 | KHUYEN_MAI | 5 | Đủ các mức giảm giá |
| 3 | THANH_TOAN | 9 | Đủ 4 trạng thái: Da_thanh_toan, Cho_thanh_toan, Da_huy, Hoan_tien |
| 4 | TAI_KHOAN_NGUOI_DUNG | 15 | 5 KH + 5 NV + 5 TX |
| 5 | KHACH_HANG | 5 | Đủ nghề nghiệp đa dạng |
| 6 | NHAN_VIEN | 5 | Đủ vai trò: Quản lý, Duyệt nội dung, CSKH, Quản lý đơn hàng |
| 7 | TAI_XE | 5 | Đủ trạng thái: Online, Offline |
| 8 | SO_DIEN_THOAI | 16 | KH An có 2 SĐT (thuộc tính đa trị) |
| 9 | GIAM_SAT | 4 | NV6 quản lý NV7, NV8, NV9, NV10 |
| 10 | MON_AN | 12 | Đủ 5 nhà hàng, mỗi NH 2-3 món |
| 11 | KHUYEN_MAI_CHO_MON_AN | 5 | Đủ các điều kiện khuyến mãi |
| 12 | GIO_HANG | 5 | Mỗi KH 1 giỏ (1:1 UNIQUE) |
| 13 | MON_AN_TRONG_GIO_HANG | 8 | Các món trong giỏ hàng |
| 14 | DON_HANG | 9 | Đủ 4 trạng thái: Da_giao, Dang_giao, Cho_xac_nhan, Da_huy |
| 15 | CHI_TIET_DON_HANG | 14 | Mỗi đơn có ít nhất 1 chi tiết |
| 16 | DANH_GIA | 7 | KH An đánh giá Phở bò tái 2 lần (PK mới) |
| 17 | TAI_XE_NHAN_DON | 6 | PK = ID_don_hang (N:1) |

### 2.2. Các thay đổi so với bản gốc

| Thay đổi | Lý do |
|----------|-------|
| Thêm THANH_TOAN #8 (Da_huy), #9 (Hoan_tien) | Đủ 4 trạng thái để demo |
| Thêm DON_HANG #8, #9 (Da_huy) | Demo trigger doanh thu P3 không tính đơn hủy |
| Thêm CHI_TIET cho DH6, DH7, DH8, DH9 | DH6, DH7 trước đây thiếu chi tiết (lỗi) |
| Sửa DH5 Tong_tien: 160k → 175k | Đúng theo tính toán: 2×45k + 45k + 40k |
| Sửa DH7 Tong_tien: 0 → 45k | Thêm chi tiết nên phải cập nhật tổng |
| Thêm SĐT cho TX15 (Son) | Trước đây thiếu |
| Thêm đánh giá lặp KH1-MA1 | Demo PK mới (ID_khach_hang, ID_mon_an, Thoi_gian) |

### 2.3. Tính toán Tong_tien

| Đơn hàng | Chi tiết | Tính toán | Tong_tien |
|----------|---------|-----------|-----------|
| DH1 | 2×Phở bò tái + 1×Phở gà | 2×45k + 40k | 130,000 |
| DH2 | 1×Bún chả + 2×Nem rán | 50k + 2×30k | 110,000 |
| DH3 | 1×Cơm tấm SBC + 1×Cơm tấm SN | 55k + 45k | 100,000 |
| DH4 | 1×Lẩu thái hải sản | 250k | 250,000 |
| DH5 | 2×Phở bò tái + 1×Phở bò chín + 1×Phở gà | 2×45k + 45k + 40k | 175,000 |
| DH6 | 1×Cơm tấm SBC | 55k | 55,000 |
| DH7 | 1×Bánh mì đặc biệt | 45k | 45,000 |
| DH8 | 1×Nem rán (đã hủy) | 30k | 30,000 |
| DH9 | 1×Phở bò tái (đã hủy) | 45k | 45,000 |

### 2.4. Edge cases trong dữ liệu

| Edge case | Dữ liệu | Mục đích demo |
|-----------|---------|---------------|
| Thuộc tính đa trị | KH An có 2 SĐT | Bảng SO_DIEN_THOAI |
| Đánh giá lặp | KH An đánh giá Phở bò tái 2 lần | PK mới (ID_kh, ID_ma, Thoi_gian) |
| Đơn hàng hủy | DH8, DH9 trạng thái Da_huy | Trigger doanh thu P3 |
| Hoàn tiền | TT9 trạng thái Hoan_tien | Quy trình thanh toán |
| Tài xế bận | TX Mạnh (ID=11) đang giao DH4 | Trigger RBND P1 |
| Đơn chờ xác nhận | DH7 Cho_xac_nhan, chưa có tài xế | Quy trình nghiệp vụ |

---

## 3. File `03_procedures_crud.sql` — Thủ Tục CRUD

### 3.1. Tổng quan 3 thủ tục

| Thủ tục | Mục đích | Số validation |
|---------|---------|--------------|
| `sp_InsertMonAn` | Thêm món ăn mới | 6 |
| `sp_UpdateMonAn` | Cập nhật thông tin món ăn | 6 + 1 cảnh báo |
| `sp_DeleteMonAn` | Xóa món ăn (hard delete) | 2 |

### 3.2. Ma trận Validate

| Kiểm tra | Insert | Update | Delete |
|----------|:------:|:------:|:------:|
| Tên không rỗng | ✅ | ✅ | — |
| Giá > 0 | ✅ | ✅ | — |
| Nhà hàng tồn tại | ✅ | ✅ | — |
| Người duyệt NOT NULL | ✅ | — | — |
| Người duyệt là NV | ✅ | ✅ | — |
| Không trùng tên trong NH (RBNM) | ✅ | ✅ | — |
| Món ăn tồn tại | — | ✅ | ✅ |
| Không có đơn đang xử lý | — | — | ✅ |
| Cảnh báo đơn hoàn thành | — | ⚠️ | — |

### 3.3. Ràng buộc ngữ nghĩa (RBNM): Không trùng tên trong cùng nhà hàng

**Tại sao đây là ràng buộc ngữ nghĩa?**
- Tên món ăn (`Ten`) không phải khóa chính (PK là `ID` auto-increment)
- Nhưng trong cùng 1 nhà hàng, 2 món cùng tên sẽ gây nhầm lẫn cho khách hàng
- Ràng buộc này không thể biểu diễn bằng CHECK đơn giản (cần truy vấn bảng)
- Được kiểm tra trong cả `sp_InsertMonAn` và `sp_UpdateMonAn`

> Lưu ý: Có thể thêm `UNIQUE(ID_nha_hang, Ten)` ở bảng `MON_AN` (file 01) để enforce ở mức schema. Nhưng theo phân công, file 01 là trách nhiệm của P1.

### 3.4. Xử lý lỗi nâng cao (TRY...CATCH)

Cả 3 thủ tục đều sử dụng `BEGIN TRY...END TRY BEGIN CATCH...END CATCH`:

- **sp_InsertMonAn**: Bắt lỗi unexpected khi INSERT
- **sp_UpdateMonAn**: Bắt lỗi unexpected khi UPDATE
- **sp_DeleteMonAn**: Đặc biệt quan trọng vì xóa cascade 5 bảng trong 1 TRANSACTION. Nếu bất kỳ bước nào lỗi → ROLLBACK toàn bộ, đảm bảo tính toàn vẹn dữ liệu.

### 3.5. Giải thích sp_DeleteMonAn (Xóa thật)

**Tại sao xóa thật (hard delete) thay vì soft delete?**

1. Đề bài yêu cầu viết procedure DELETE thật sự
2. Đã có validation chặt: không xóa nếu còn đơn hàng đang xử lý
3. Dùng TRANSACTION đảm bảo: nếu xóa 1 bảng liên quan bị lỗi → rollback tất cả
4. Thứ tự xóa cascade đúng dependency:
   ```
   KHUYEN_MAI_CHO_MON_AN → MON_AN_TRONG_GIO_HANG → DANH_GIA → CHI_TIET_DON_HANG → MON_AN
   ```

### 3.6. Test Cases (13 test cases)

| # | Thủ tục | Kịch bản | Kết quả mong đợi |
|---|---------|---------|------------------|
| 1 | INSERT | Thêm món mới hợp lệ | ✅ Thành công |
| 2 | INSERT | Giá âm | ❌ Lỗi: Giá phải > 0 |
| 3 | INSERT | NH không tồn tại | ❌ Lỗi: NH không tồn tại |
| 4 | INSERT | Thiếu người duyệt (NULL) | ❌ Lỗi: Người duyệt bắt buộc |
| 5 | INSERT | Người duyệt là KH (ID=1) | ❌ Lỗi: Không phải NV |
| 6 | INSERT | Trùng tên trong cùng NH | ❌ Lỗi: RBNM |
| 7 | UPDATE | Đổi giá thành công | ✅ Thành công |
| 8 | UPDATE | Món ăn không tồn tại | ❌ Lỗi: Không tồn tại |
| 9 | UPDATE | Trùng tên trong cùng NH | ❌ Lỗi: RBNM |
| 10 | UPDATE | Đổi tên không trùng | ✅ Thành công |
| 11 | DELETE | Món trong đơn chưa xong | ❌ Lỗi: Có đơn đang xử lý |
| 12 | DELETE | Món không trong đơn nào | ✅ Thành công |
| 13 | DELETE | Món chỉ trong đơn đã xong/hủy | ✅ Thành công |

---

## 4. Hướng Dẫn Cài Đặt & Chạy Code

### 4.1. Cài đặt SQL Server Express

1. Truy cập: https://www.microsoft.com/en-us/sql-server/sql-server-downloads
2. Tải **SQL Server 2022 Express** (miễn phí)
3. Chạy installer → chọn **Basic** → cài đặt mặc định
4. Ghi nhớ tên instance (thường là `localhost\SQLEXPRESS`)

### 4.2. Cài đặt SQL Server Management Studio (SSMS)

1. Truy cập: https://learn.microsoft.com/en-us/sql/ssms/download-sql-server-management-studio-ssms
2. Tải **SSMS** (miễn phí) → cài đặt
3. Mở SSMS → Server name: `localhost\SQLEXPRESS` → Authentication: **Windows Authentication**.
4. **Quan trọng (Lỗi SSL):** Click vào **Options >>** (hoặc tab **Connection Properties**) → Tích chọn **Trust server certificate** → Nhấn **Connect**.

### 4.3. Chạy code SQL

Trong SSMS, chạy theo thứ tự:

```
File 01 → File 02 → File 03 → File 04 → File 05 → File 06
```

Cách chạy từng file:
1. **File → Open → File** → chọn file SQL
2. Nhấn **F5** hoặc nút **Execute**
3. Kiểm tra tab **Messages** ở dưới → nếu có dòng `=== ... THANH CONG ===` là OK

### 4.4. Chạy Test Cases

Sau khi chạy xong file 01, 02, 03:
1. Mở file `03_procedures_crud.sql`
2. Tìm phần `TEST CASES` ở cuối file
3. Bỏ dấu `--` trước dòng `EXEC sp_...` muốn test
4. Bôi đen dòng đó → **F5**
5. Xem kết quả ở tab **Messages**

---

## 5. Kết Nối Với Các Phần Khác

### P2 giao cho P3 (Triggers & CRUD Screen):
- Dữ liệu mẫu đủ đơn hàng + chi tiết để test trigger tính Tong_tien và Doanh_thu
- Có đơn Da_huy (DH8, DH9) để chứng minh trigger chỉ tính đơn Da_giao
- 3 thủ tục CRUD để P3 gọi từ màn hình CRUD trên app

### P2 giao cho P4 (Query Procedures & List Screen):
- Dữ liệu mẫu đủ các trạng thái đơn hàng để test sp_LichSuDonHangCuaKhach
- Có nhiều nhà hàng với đơn Da_giao để test sp_ThongKeNhaHangDoanhThuCao

### P2 giao cho P5 (Functions & Backend):
- KH An (ID=1) có nhiều đơn → test fn_XepHangKhachHang
- NH Phở Thin (ID=1) có nhiều đơn Da_giao → test fn_TinhDoanhThu
