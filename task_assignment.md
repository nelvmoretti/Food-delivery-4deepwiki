# Phân Chia Nhiệm Vụ — BTL2 Hệ CSDL (Logistic Giao Đồ Ăn)

## Ý Tưởng Chính

```
  Person 1                Person 2                Person 3                Person 4                Person 5
 ┌────────────────┐   ┌────────────────┐   ┌────────────────┐   ┌────────────────┐   ┌────────────────────┐
 │ SCHEMA &       │   │ DATA &         │   │ TRIGGERS &     │   │ QUERY PROCS &  │   │ FUNCTIONS &        │
 │ CONSTRAINTS    │   │ CRUD PROCS     │   │ CRUD SCREEN    │   │ LIST SCREEN    │   │ BACKEND & SCREEN   │
 │                │   │                │   │                │   │                │   │                    │
 │ • 17 bảng DDL  │   │ • Sample data  │   │ • Trigger NV   │   │ • sp_LichSu    │   │ • fn_DoanhThu      │
 │ • PK/FK/CHECK  │──▶│ • sp_Insert    │──▶│ • Trigger DX   │──▶│ • sp_ThongKe   │──▶│ • fn_XepHang       │
 │ • Trigger RBND │   │ • sp_Update    │   │ • Screen CRUD  │   │ • Screen List  │   │ • Backend API      │
 │                │   │ • sp_Delete    │   │   (MON_AN)     │   │   (DON_HANG)   │   │ • Screen Extra     │
 └────────────────┘   └────────────────┘   └────────────────┘   └────────────────┘   └────────────────────┘

   ★★★★☆ difficulty     ★★★☆☆ difficulty     ★★★★☆ difficulty     ★★★☆☆ difficulty     ★★★★★ difficulty
   ~2.5 điểm            ~2.0 điểm            ~1.5 điểm            ~2.0 điểm            ~2.0 điểm
```

> [!TIP]
> P1 và P3 nặng về logic SQL, P5 nặng về fullstack (backend + frontend). P2 và P4 cân bằng giữa SQL và app. **Mỗi thành viên đều có ít nhất 1 phần SQL trong Phần 2** (yêu cầu bắt buộc của đề).

---

## Tổng Quan Phân Điểm Đề Bài

| Phần | Nội dung | Điểm | File SQL |
|------|----------|------|----------|
| 1.1 | Tạo bảng + ràng buộc | 2 | `01_create_tables.sql` |
| 1.2 | Dữ liệu mẫu (≥5 dòng/bảng) | 1 | `02_sample_data.sql` |
| 2.1 | CRUD procedures (MON_AN) | 1 | `03_procedures_crud.sql` |
| 2.2.1 | Trigger ràng buộc nghiệp vụ | 0.5 | `04_triggers.sql` |
| 2.2.2 | Trigger thuộc tính dẫn xuất | 0.5 | `04_triggers.sql` |
| 2.3 | 2 thủ tục truy vấn | 1 | `05_procedures_query.sql` |
| 2.4 | 2 hàm (cursor, IF/LOOP) | 1 | `06_functions.sql` |
| 3.1 | Màn hình CRUD (MON_AN) | 1 | Mobile App |
| 3.2 | Màn hình danh sách + search/sort | 1 | Mobile App |
| 3.3 | Màn hình minh họa thủ tục/hàm | 1 | Mobile App |

---

## Person 1 — Schema & Business Constraint

**Mục tiêu**: Thiết kế và hiện thực toàn bộ lược đồ CSDL quan hệ 17 bảng + viết trigger kiểm tra ràng buộc nghiệp vụ.

### Các task

| Task | Mục tiêu | Gợi ý hướng tiếp cận |
|------|----------|----------------------|
| **DDL 17 bảng** | Tạo tất cả bảng với đúng kiểu dữ liệu, PK, FK, DEFAULT | Theo thứ tự dependency: NHA_HANG → TAI_KHOAN → ... → TAI_XE_NHAN_DON |
| **Constraints CHECK** | Hiện thực các ràng buộc kiểm tra dữ liệu | Email format, giá > 0, trạng thái IN(...), xếp hạng 1–5, SĐT format |
| **Constraints FK** | Đảm bảo toàn vẹn tham chiếu giữa các bảng | Xử lý ISA (KHACH_HANG, NHAN_VIEN, TAI_XE → TAI_KHOAN_NGUOI_DUNG) |
| **Trigger RBND** | Tài xế chỉ nhận đơn mới khi không có đơn đang giao | `trg_CheckTaiXeNhanDon` trên INSERT/UPDATE TAI_XE_NHAN_DON, tự cập nhật trạng thái tài xế |

### Bảng chịu trách nhiệm

| # | Bảng | Ghi chú |
|---|------|---------|
| 1 | NHA_HANG | Doanh_thu là thuộc tính dẫn xuất (DEFAULT 0) |
| 2 | KHUYEN_MAI | CHECK Tien_giam_gia ≥ 0 |
| 3 | THANH_TOAN | CHECK phương thức IN 4 loại, trạng thái IN 4 loại |
| 4 | TAI_KHOAN_NGUOI_DUNG | CHECK email format, UNIQUE email, phân loại 3 loại |
| 5–7 | KHACH_HANG, NHAN_VIEN, TAI_XE | ISA inheritance từ TAI_KHOAN, FK(ID) |
| 8 | SO_DIEN_THOAI | CHECK format SĐT, FK → TAI_KHOAN |
| 9 | GIAM_SAT | CHECK không tự quản lý, PK = Nguoi_bi_quan_ly_ID |
| 10–17 | MON_AN → TAI_XE_NHAN_DON | Các bảng còn lại theo ERD |

> [!IMPORTANT]
> ### Lưu ý cho P1
> - **Thứ tự DROP** ngược dependency khi re-create
> - DON_HANG có thêm `ID_nhan_vien` (mandatory relationship mới)
> - Trigger RBND **phải ROLLBACK** nếu vi phạm, không chỉ RAISERROR
> - Chuẩn bị **dữ liệu test** minh họa trigger (thành công + thất bại)

---

## Person 2 — Sample Data & CRUD Procedures

**Mục tiêu**: Tạo dữ liệu mẫu có ý nghĩa cho tất cả 17 bảng + viết 3 thủ tục CRUD cho bảng MON_AN với validate đầy đủ.

### Các task

| Task | Mục tiêu | Gợi ý hướng tiếp cận |
|------|----------|----------------------|
| **Sample Data** | Nhập ≥5 dòng/bảng, dữ liệu có ý nghĩa thực tế | 5 nhà hàng VN, 5 KH, 5 NV, 5 TX, 12+ món ăn, 7+ đơn hàng |
| **sp_InsertMonAn** | Thêm món ăn với validate đầy đủ | Check: tên không rỗng, giá > 0, nhà hàng tồn tại, người duyệt là NV, không trùng tên trong cùng NH |
| **sp_UpdateMonAn** | Sửa món ăn, chỉ cập nhật trường được truyền | Dùng ISNULL(@param, cot_cu), cảnh báo nếu món đã có trong đơn hoàn thành |
| **sp_DeleteMonAn** | Xóa món ăn khi NH ngừng bán | Không xóa nếu còn đơn chưa hoàn thành, xóa cascade: khuyến mãi, giỏ hàng, đánh giá |

### Validate bắt buộc trong CRUD

| Kiểm tra | sp_Insert | sp_Update | sp_Delete |
|----------|:---------:|:---------:|:---------:|
| Tên không rỗng | ✅ | ✅ | — |
| Giá > 0 | ✅ | ✅ | — |
| Nhà hàng tồn tại | ✅ | ✅ | — |
| Người duyệt là NV | ✅ | ✅ | — |
| Không trùng tên trong NH | ✅ | — | — |
| Món ăn tồn tại | — | ✅ | ✅ |
| Không có đơn đang xử lý | — | — | ✅ |

> [!IMPORTANT]
> ### Lưu ý cho P2
> - Dữ liệu mẫu phải **đủ để demo** tất cả trigger, procedure, function
> - Cần có đơn hàng ở nhiều trạng thái khác nhau (Cho_xac_nhan, Da_giao, Da_huy...)
> - RAISERROR phải **cụ thể** lỗi gì, không ghi chung chung
> - Chuẩn bị **test case** cho cả trường hợp thành công và thất bại

---

## Person 3 — Derived Triggers & CRUD Screen

**Mục tiêu**: Viết trigger tính thuộc tính dẫn xuất (Tong_tien, Doanh_thu) + hiện thực màn hình CRUD cho MON_AN trên app.

### Các task

| Task | Mục tiêu | Gợi ý hướng tiếp cận |
|------|----------|----------------------|
| **trg_UpdateTongTienDonHang** | Tự động tính Tong_tien khi CHI_TIET thay đổi | AFTER INSERT/UPDATE/DELETE trên CHI_TIET_DON_HANG → SUM(So_luong × Gia_chot) |
| **trg_UpdateDoanhThuNhaHang** | Tự động cập nhật Doanh_thu khi DON_HANG thay đổi | AFTER INSERT/UPDATE/DELETE trên DON_HANG → SUM(Tong_tien) WHERE Trang_thai = 'Da_giao' |
| **CRUD Screen** | Màn hình thêm/sửa/xóa MON_AN (Part 3.1) | React Native form gọi API backend → backend gọi sp_Insert/Update/Delete |

### Chuỗi trigger dẫn xuất

```
CHI_TIET_DON_HANG thay đổi
        │
        ▼
trg_UpdateTongTienDonHang
  → Tính lại: Tong_tien = SUM(So_luong × Gia_chot)
  → UPDATE DON_HANG.Tong_tien
        │
        ▼
trg_UpdateDoanhThuNhaHang (bị kích hoạt do UPDATE DON_HANG)
  → Tính lại: Doanh_thu = SUM(Tong_tien) WHERE Trang_thai = 'Da_giao'
  → UPDATE NHA_HANG.Doanh_thu
```

> [!IMPORTANT]
> ### Lưu ý cho P3
> - Trigger Doanh_thu **phải tính Tong_tien trước** — KHÔNG giả sử Tong_tien đã có sẵn
> - Doanh_thu chỉ từ đơn `Da_giao`, KHÔNG tính đơn đang xử lý/đã hủy
> - CRUD Screen phải gọi **stored procedure** (sp_InsertMonAn...), KHÔNG dùng raw SQL
> - Chuẩn bị dữ liệu demo: thêm chi tiết → xem Tong_tien tự cập nhật → xem Doanh_thu tự cập nhật

---

## Person 4 — Query Procedures & List Screen

**Mục tiêu**: Viết 2 thủ tục truy vấn phức tạp + hiện thực màn hình hiển thị danh sách với search/sort/filter.

### Các task

| Task | Mục tiêu | Gợi ý hướng tiếp cận |
|------|----------|----------------------|
| **sp_LichSuDonHangCuaKhach** | Truy vấn ≥2 bảng + WHERE + ORDER BY | JOIN DON_HANG, KHACH_HANG, TAI_KHOAN_NGUOI_DUNG, NHA_HANG; filter theo KH + khoảng thời gian |
| **sp_ThongKeNhaHangDoanhThuCao** | Truy vấn aggregate + GROUP BY + HAVING + WHERE + ORDER BY | JOIN NHA_HANG, DON_HANG; filter Da_giao + khoảng thời gian; HAVING SUM ≥ mức tối thiểu |
| **List Screen** | Giao diện hiển thị danh sách (Part 3.2) | Hiển thị kết quả từ sp_LichSuDonHangCuaKhach, có search box, date picker, sort |

### Yêu cầu thủ tục truy vấn

| Yêu cầu đề bài | sp_LichSu | sp_ThongKe |
|----------------|:---------:|:----------:|
| ≥ 2 bảng JOIN | ✅ (4 bảng) | ✅ (2 bảng) |
| WHERE | ✅ | ✅ |
| ORDER BY | ✅ | ✅ |
| Aggregate function | — | ✅ (COUNT, SUM) |
| GROUP BY | — | ✅ |
| HAVING | — | ✅ |
| Liên quan bảng 2.1 (MON_AN) | ✅ (qua DON_HANG) | ✅ (qua DON_HANG) |

### List Screen yêu cầu

| Chức năng | Mô tả |
|-----------|-------|
| Hiển thị danh sách | Gọi sp_LichSuDonHangCuaKhach với tham số từ UI |
| Tìm kiếm | TextBox nhập ID khách hàng |
| Lọc thời gian | Date picker cho TuNgay, DenNgay |
| Sắp xếp | Sort theo thời gian, tổng tiền |
| Cập nhật/Xóa | Chọn 1 dòng → sửa/xóa đơn hàng |

> [!IMPORTANT]
> ### Lưu ý cho P4
> - Ít nhất 1 thủ tục phải **liên quan đến bảng MON_AN** (câu 2.1)
> - Tham số WHERE/HAVING do **người dùng nhập** qua textbox/combo box/date picker
> - Thao tác thêm/sửa/xóa trên list phải **gọi stored procedure**, không dùng raw SQL

---

## Person 5 — Functions & Backend & Extra Screen

**Mục tiêu**: Viết 2 hàm phức tạp (cursor + IF/LOOP) + thiết lập backend API + hiện thực màn hình minh họa hàm.

### Các task

| Task | Mục tiêu | Gợi ý hướng tiếp cận |
|------|----------|----------------------|
| **fn_TinhDoanhThu** | Tính doanh thu NH trong khoảng thời gian bằng cursor | Validate input → cursor duyệt đơn Da_giao → cộng dồn → return tổng |
| **fn_XepHangKhachHang** | Xếp hạng KH theo tổng chi tiêu bằng cursor + IF | Cursor sort giảm dần tổng chi → loop đếm rank → return thứ hạng |
| **Backend API** | Express + mssql kết nối SQL Server | Routes: `/api/monan` (CRUD), `/api/donhang` (list), `/api/thongke` (functions) |
| **Extra Screen** | Màn hình minh họa fn_TinhDoanhThu hoặc fn_XepHangKhachHang (Part 3.3) | Giao diện nhập ID NH + khoảng ngày → hiển thị doanh thu |

### Yêu cầu hàm

| Yêu cầu đề bài | fn_TinhDoanhThu | fn_XepHangKhachHang |
|----------------|:---------------:|:-------------------:|
| Con trỏ (cursor) | ✅ | ✅ |
| IF | ✅ (validate) | ✅ (so sánh rank) |
| LOOP (WHILE) | ✅ (FETCH loop) | ✅ (FETCH loop) |
| Truy vấn dữ liệu | ✅ | ✅ |
| Tham số đầu vào | ✅ (3 params) | ✅ (1 param) |
| Kiểm tra tham số | ✅ (ngày, NH tồn tại) | ✅ (KH tồn tại) |

### Backend API Endpoints

| Method | Endpoint | Mô tả | Gọi SQL |
|--------|----------|-------|---------|
| POST | `/api/monan` | Thêm món ăn | EXEC sp_InsertMonAn |
| PUT | `/api/monan/:id` | Sửa món ăn | EXEC sp_UpdateMonAn |
| DELETE | `/api/monan/:id` | Xóa món ăn | EXEC sp_DeleteMonAn |
| GET | `/api/donhang/lichsu` | Lịch sử đơn hàng | EXEC sp_LichSuDonHangCuaKhach |
| GET | `/api/thongke/doanhthu` | Thống kê doanh thu | EXEC sp_ThongKeNhaHangDoanhThuCao |
| GET | `/api/fn/doanhthu` | Gọi hàm doanh thu | SELECT dbo.fn_TinhDoanhThu |
| GET | `/api/fn/xephang` | Gọi hàm xếp hạng | SELECT dbo.fn_XepHangKhachHang |

> [!IMPORTANT]
> ### Lưu ý cho P5
> - Hàm TSQL **không được dùng RAISERROR** — dùng return mã lỗi (-1, -2) rồi xử lý ở app
> - Backend **PHẢI KẾT NỐI THẬT** với SQL Server, không fake data
> - Chuẩn bị **câu lệnh + dữ liệu demo** gọi hàm khi báo cáo

---

## Ràng Buộc Chung (Từ Đề Bài — Cả 5 Người)

> [!CAUTION]
> ### Yêu cầu BẮT BUỘC
> 1. ✅ Mỗi thành viên **PHẢI viết ít nhất 1 câu** trong Phần 2 (trigger/procedure/function)
> 2. ✅ Mọi thao tác CRUD trên app **PHẢI gọi stored procedure**, KHÔNG dùng raw SQL
> 3. ✅ App **PHẢI KẾT NỐI THẬT** với CSDL — nếu không sẽ 0 điểm phần App
> 4. ✅ Mỗi người phải **nắm được nội dung** tất cả các phần (dù không phải phần mình làm)

> [!WARNING]
> ### Điểm trừ cần tránh
> 1. ❌ Các hàm/thủ tục/trigger có **nội dung gần giống nhau**
> 2. ❌ Dữ liệu chuẩn bị **quá ít hoặc không có ý nghĩa**
> 3. ❌ Thành viên **không hiểu** phần người khác làm
> 4. ❌ Ràng buộc CHECK được thì **không dùng trigger** thay

---

## Kết Nối Dữ Liệu Giữa Các Phần

```
P1 giao P2:
  - Schema 17 bảng đã tạo (01_create_tables.sql)
  - P2 INSERT dữ liệu mẫu theo đúng thứ tự dependency

P2 giao P3:
  - Dữ liệu mẫu đủ để test trigger (đơn hàng + chi tiết + nhà hàng)
  - CRUD procedures để P3 gọi từ app screen

P2 giao P4:
  - Dữ liệu mẫu đủ để test query procedures
  - CRUD procedures để P4 dùng trên list screen

P4 giao P5:
  - Query procedures (sp endpoints) để P5 tạo API routes
  - P5 tạo backend API → P3, P4 gọi từ mobile app

P5 giao P3 + P4:
  - Backend API endpoints sẵn sàng
  - Hướng dẫn kết nối: base URL, request/response format
```

> [!TIP]
> Thống nhất **cấu trúc response API** trước khi code: `{ success: boolean, data: [...], message: string }`. Tránh phải sửa khi ghép.

---

## Timeline Gợi Ý

| Ngày | P1 | P2 | P3 | P4 | P5 |
|------|----|----|----|----|-----|
| 1–2 | DDL 17 bảng + constraints | Chuẩn bị dữ liệu mẫu | Đọc hiểu chuỗi trigger dẫn xuất | Thiết kế 2 thủ tục truy vấn | Setup backend + kết nối DB |
| 2–3 | Viết trigger RBND | Viết 3 CRUD procedures | Viết 2 trigger dẫn xuất | Code 2 thủ tục truy vấn | Viết 2 functions |
| 3–4 | Test DDL + trigger | Test CRUD + fix data | Code CRUD screen | Code list screen | Tạo API routes |
| 4–5 | Cả team ghép: Backend ↔ Mobile App → test end-to-end → fix bugs |
| 5–6 | Cả team: viết báo cáo + chuẩn bị demo + rehearsal trình bày |
