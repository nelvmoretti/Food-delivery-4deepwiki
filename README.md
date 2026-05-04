# HƯỚNG DẪN HIỆN THỰC DỰ ÁN BTL2 - LOGISTIC GIAO ĐỒ ĂN

> **QUAN TRỌNG:** Những sai sót về mặt thiết kế CSDL (các ràng buộc 1:1, 1:N, N:M và thuộc tính dẫn xuất) đã được đánh giá và ghi rõ cách sửa tại file `THAY ĐỔI VỚI DATABASE.md`. Toàn team phải đọc file đó trước khi bắt tay vào code!

---

## 📅 Lộ trình phát triển (Roadmap)

Dự án được chia làm 3 Phase. **Phải tuân thủ nghiêm ngặt thứ tự này** vì các phase sau phụ thuộc vào phase trước.

### Phase 1: Chuẩn hóa Database & Dữ liệu mẫu
- **Ai làm:** P1 (Schema) + P2 (Data) — **chạy song song một phần, P1 phải xong trước P2**.
- **Output:** DB chạy không lỗi, có ≥5 dòng/bảng, sẵn sàng cho Phase 2.

### Phase 2: Phát triển Logic Database (Triggers, Procedures, Functions)
- **Ai làm:** P1 (Trigger RBND) + P2 (CRUD Procs) + P3 (Trigger Dẫn xuất) + P4 (Query Procs) + P5 (Functions) — **có thể làm song song** sau khi Phase 1 xong.
- **Output:** Tất cả file SQL hoàn chỉnh, mỗi người ít nhất 1 phần SQL.

### Phase 3: Kết nối Ứng dụng (Mobile/Web/Desktop)
- **Ai làm:** P3 (CRUD Screen) + P4 (List Screen) + P5 (Backend API + Extra Screen) — **P5 phải setup backend trước** để P3, P4 gọi API.
- **Output:** App kết nối thật với CSDL, demo đầy đủ.

---

## 📊 Bảng điểm theo đề bài

| Phần | Nội dung | Điểm | File SQL | Người phụ trách |
|------|----------|------|----------|-----------------|
| 1.1 | Tạo bảng + ràng buộc | 2 | `01_create_tables.sql` | P1 |
| 1.2 | Dữ liệu mẫu (≥5 dòng/bảng) | 1 | `02_sample_data.sql` | P2 |
| 2.1 | CRUD procedures (MON_AN) | 1 | `03_procedures_crud.sql` | P2 |
| 2.2.1 | Trigger ràng buộc nghiệp vụ | 0.5 | `04_triggers.sql` | P1 |
| 2.2.2 | Trigger thuộc tính dẫn xuất | 0.5 | `04_triggers.sql` | P3 |
| 2.3 | 2 thủ tục truy vấn | 1 | `05_procedures_query.sql` | P4 |
| 2.4 | 2 hàm (cursor, IF/LOOP) | 1 | `06_functions.sql` | P5 |
| 3.1 | Màn hình CRUD (MON_AN) | 1 | App | P3 |
| 3.2 | Màn hình danh sách + search/sort | 1 | App | P4 |
| 3.3 | Màn hình minh họa thủ tục/hàm | 1 | App | P5 |

---

## 👥 Phân công công việc (5 thành viên)

```
  Person 1                Person 2                Person 3                Person 4                Person 5
 ┌────────────────┐   ┌────────────────┐   ┌────────────────┐   ┌────────────────┐   ┌────────────────────┐
 │ SCHEMA &       │   │ DATA &         │   │ TRIGGERS &     │   │ QUERY PROCS &  │   │ FUNCTIONS &        │
 │ CONSTRAINTS    │   │ CRUD PROCS     │   │ CRUD SCREEN    │   │ LIST SCREEN    │   │ BACKEND & SCREEN   │
 │                │   │                │   │                │   │                │   │                    │
 │ • 17 bảng DDL  │   │ • Sample data  │   │ • Trigger DX   │   │ • sp_LichSu    │   │ • fn_DoanhThu      │
 │ • PK/FK/CHECK  │──▶│ • sp_Insert    │──▶│ • Trigger DX2  │──▶│ • sp_ThongKe   │──▶│ • fn_XepHang       │
 │ • Trigger RBND │   │ • sp_Update    │   │ • Screen CRUD  │   │ • Screen List  │   │ • Backend API      │
 │                │   │ • sp_Delete    │   │   (MON_AN)     │   │   (DON_HANG)   │   │ • Screen Extra     │
 └────────────────┘   └────────────────┘   └────────────────┘   └────────────────┘   └────────────────────┘
```

---

### 🧑‍💻 Person 1 — Schema & Business Constraint (Người dọn đường)

**Mục tiêu:** Thiết kế toàn bộ 17 bảng + viết Trigger ràng buộc nghiệp vụ.

| Phase | Task | Chi tiết |
|-------|------|----------|
| **Phase 1** | DDL 17 bảng | Tạo tất cả bảng với PK, FK, DEFAULT theo thứ tự dependency (NHA_HANG → TAI_KHOAN → ... → TAI_XE_NHAN_DON). Áp dụng các sửa đổi trong `THAY ĐỔI VỚI DATABASE.md`. |
| **Phase 1** | Constraints CHECK | Email format, giá > 0, trạng thái IN(...), xếp hạng 1–5, SĐT format. |
| **Phase 1** | Constraints FK | Xử lý ISA (KHACH_HANG, NHAN_VIEN, TAI_XE → TAI_KHOAN_NGUOI_DUNG). |
| **Phase 2** | Trigger RBND | `trg_CheckTaiXeNhanDon`: Tài xế chỉ nhận đơn mới khi không có đơn đang giao. INSERT/UPDATE trên TAI_XE_NHAN_DON. Phải ROLLBACK nếu vi phạm. Tự cập nhật trạng thái tài xế. |

**Bảng phụ trách:** NHA_HANG, KHUYEN_MAI, THANH_TOAN, TAI_KHOAN_NGUOI_DUNG, KHACH_HANG, NHAN_VIEN, TAI_XE, SO_DIEN_THOAI, GIAM_SAT, MON_AN, GIO_HANG, DON_HANG, CHI_TIET_DON_HANG, DANH_GIA, KHUYEN_MAI_CHO_MON_AN, MON_AN_TRONG_GIO_HANG, TAI_XE_NHAN_DON.

> **Lưu ý:**
> - Thứ tự DROP ngược dependency khi re-create.
> - DON_HANG có thêm `ID_nhan_vien` (mandatory relationship mới).
> - Chuẩn bị **dữ liệu test** minh họa trigger (thành công + thất bại).

---

### 🧑‍💻 Person 2 — Sample Data & CRUD Procedures

**Mục tiêu:** Tạo dữ liệu mẫu ≥5 dòng/bảng + viết 3 thủ tục CRUD cho bảng MON_AN với validate đầy đủ.

| Phase | Task | Chi tiết |
|-------|------|----------|
| **Phase 1** | Sample Data | Nhập ≥5 dòng/bảng dữ liệu có ý nghĩa thực tế: 5 nhà hàng VN, 5 KH, 5 NV, 5 TX, 12+ món ăn, 7+ đơn hàng (nhiều trạng thái khác nhau: Cho_xac_nhan, Da_giao, Da_huy...). |
| **Phase 2** | `sp_InsertMonAn` | Validate: tên không rỗng, giá > 0, nhà hàng tồn tại, người duyệt là NV, không trùng tên trong cùng NH. |
| **Phase 2** | `sp_UpdateMonAn` | Cập nhật chỉ trường được truyền. Dùng `ISNULL(@param, cot_cu)`. Cảnh báo nếu món đã có trong đơn hoàn thành. |
| **Phase 2** | `sp_DeleteMonAn` | Không xóa nếu còn đơn chưa hoàn thành. Xóa cascade: khuyến mãi, giỏ hàng, đánh giá. |

**Ma trận Validate bắt buộc:**

| Kiểm tra | sp_Insert | sp_Update | sp_Delete |
|----------|:---------:|:---------:|:---------:|
| Tên không rỗng | ✅ | ✅ | — |
| Giá > 0 | ✅ | ✅ | — |
| Nhà hàng tồn tại | ✅ | ✅ | — |
| Người duyệt là NV | ✅ | ✅ | — |
| Không trùng tên trong NH | ✅ | — | — |
| Món ăn tồn tại | — | ✅ | ✅ |
| Không có đơn đang xử lý | — | — | ✅ |

> **Lưu ý:**
> - Dữ liệu mẫu phải **đủ để demo** tất cả trigger, procedure, function của cả 5 người.
> - RAISERROR phải **cụ thể** lỗi gì (VD: "Lỗi: Giá món ăn phải lớn hơn 0"), không ghi chung chung.
> - Chuẩn bị **test case** cho cả trường hợp thành công và thất bại.

---

### 🧑‍💻 Person 3 — Derived Triggers & CRUD Screen

**Mục tiêu:** Viết trigger tính thuộc tính dẫn xuất (Tong_tien, Doanh_thu) + hiện thực màn hình CRUD cho MON_AN trên app.

| Phase | Task | Chi tiết |
|-------|------|----------|
| **Phase 2** | `trg_UpdateTongTienDonHang` | AFTER INSERT/UPDATE/DELETE trên CHI_TIET_DON_HANG → Tính `Tong_tien = SUM(So_luong × Gia_chot)` → UPDATE DON_HANG. |
| **Phase 2** | `trg_UpdateDoanhThuNhaHang` | AFTER INSERT/UPDATE/DELETE trên DON_HANG → Tính `Doanh_thu = SUM(Tong_tien) WHERE Trang_thai = 'Da_giao'` → UPDATE NHA_HANG. |
| **Phase 3** | CRUD Screen (Yêu cầu 3.1) | Màn hình thêm/sửa/xóa MON_AN. Gọi API backend → backend gọi sp_Insert/Update/DeleteMonAn. |

**Chuỗi trigger dẫn xuất:**
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

> **Lưu ý:**
> - Trigger Doanh_thu **phải tính Tong_tien trước** — KHÔNG giả sử Tong_tien đã có sẵn.
> - Doanh_thu chỉ từ đơn `Da_giao`, KHÔNG tính đơn đang xử lý/đã hủy.
> - CRUD Screen phải gọi **stored procedure**, KHÔNG dùng raw SQL.
> - Chuẩn bị demo: thêm chi tiết → xem Tong_tien tự cập nhật → xem Doanh_thu tự cập nhật.

---

### 🧑‍💻 Person 4 — Query Procedures & List Screen

**Mục tiêu:** Viết 2 thủ tục truy vấn phức tạp + hiện thực màn hình hiển thị danh sách với search/sort/filter.

| Phase | Task | Chi tiết |
|-------|------|----------|
| **Phase 2** | `sp_LichSuDonHangCuaKhach` | JOIN 4 bảng (DON_HANG, KHACH_HANG, TAI_KHOAN_NGUOI_DUNG, NHA_HANG). Filter theo KH + khoảng thời gian. Có WHERE + ORDER BY. |
| **Phase 2** | `sp_ThongKeNhaHangDoanhThuCao` | JOIN NHA_HANG + DON_HANG. Filter Da_giao + khoảng thời gian. Có Aggregate (COUNT, SUM) + GROUP BY + HAVING (SUM ≥ mức tối thiểu) + ORDER BY. |
| **Phase 3** | List Screen (Yêu cầu 3.2) | Hiển thị kết quả từ sp_LichSuDonHangCuaKhach. Có search box (ID KH), date picker (TuNgay, DenNgay), sort (thời gian, tổng tiền). Chọn 1 dòng → sửa/xóa đơn hàng. |

**Checklist đáp ứng yêu cầu đề:**

| Yêu cầu đề bài | sp_LichSu | sp_ThongKe |
|----------------|:---------:|:----------:|
| ≥ 2 bảng JOIN | ✅ (4 bảng) | ✅ (2 bảng) |
| WHERE | ✅ | ✅ |
| ORDER BY | ✅ | ✅ |
| Aggregate function | — | ✅ (COUNT, SUM) |
| GROUP BY | — | ✅ |
| HAVING | — | ✅ |
| Liên quan bảng MON_AN (câu 2.1) | ✅ (qua DON_HANG) | ✅ (qua DON_HANG) |

> **Lưu ý:**
> - Ít nhất 1 thủ tục phải **liên quan đến bảng MON_AN** (yêu cầu đề).
> - Tham số WHERE/HAVING do **người dùng nhập** qua textbox/combo box/date picker trên UI.
> - Thao tác thêm/sửa/xóa trên list phải **gọi stored procedure**, không dùng raw SQL.

---

### 🧑‍💻 Person 5 — Functions & Backend & Extra Screen

**Mục tiêu:** Viết 2 hàm phức tạp (cursor + IF/LOOP) + thiết lập backend API kết nối SQL Server thật + hiện thực màn hình minh họa hàm.

| Phase | Task | Chi tiết |
|-------|------|----------|
| **Phase 2** | `fn_TinhDoanhThu` | Tham số: @ID_nha_hang, @TuNgay, @DenNgay. Validate input → cursor duyệt đơn Da_giao → cộng dồn → return tổng. |
| **Phase 2** | `fn_XepHangKhachHang` | Tham số: @ID_khach_hang. Cursor sort giảm dần tổng chi → loop đếm rank → return thứ hạng. |
| **Phase 3** | Backend API (Express + mssql) | Kết nối SQL Server thật. Tạo routes cho CRUD, list, và functions. |
| **Phase 3** | Extra Screen (Yêu cầu 3.3) | Giao diện nhập ID NH + khoảng ngày → hiển thị doanh thu. Hoặc nhập ID KH → hiển thị xếp hạng. |

**Checklist đáp ứng yêu cầu đề (2 hàm):**

| Yêu cầu đề bài | fn_TinhDoanhThu | fn_XepHangKhachHang |
|----------------|:---------------:|:-------------------:|
| Con trỏ (cursor) | ✅ | ✅ |
| IF | ✅ (validate) | ✅ (so sánh rank) |
| LOOP (WHILE) | ✅ (FETCH loop) | ✅ (FETCH loop) |
| Truy vấn dữ liệu | ✅ | ✅ |
| Tham số đầu vào | ✅ (3 params) | ✅ (1 param) |
| Kiểm tra tham số | ✅ (ngày, NH tồn tại) | ✅ (KH tồn tại) |

**Backend API Endpoints:**

| Method | Endpoint | Mô tả | Gọi SQL |
|--------|----------|-------|---------| 
| POST | `/api/monan` | Thêm món ăn | EXEC sp_InsertMonAn |
| PUT | `/api/monan/:id` | Sửa món ăn | EXEC sp_UpdateMonAn |
| DELETE | `/api/monan/:id` | Xóa món ăn | EXEC sp_DeleteMonAn |
| GET | `/api/donhang/lichsu` | Lịch sử đơn hàng | EXEC sp_LichSuDonHangCuaKhach |
| GET | `/api/thongke/doanhthu` | Thống kê doanh thu | EXEC sp_ThongKeNhaHangDoanhThuCao |
| GET | `/api/fn/doanhthu` | Gọi hàm doanh thu | SELECT dbo.fn_TinhDoanhThu |
| GET | `/api/fn/xephang` | Gọi hàm xếp hạng | SELECT dbo.fn_XepHangKhachHang |

> **Lưu ý:**
> - Hàm TSQL **không được dùng RAISERROR** — dùng return mã lỗi (-1, -2) rồi xử lý ở app.
> - Backend **PHẢI KẾT NỐI THẬT** với SQL Server, không fake data.
> - Chuẩn bị **câu lệnh + dữ liệu demo** gọi hàm khi báo cáo.

---

## ⚠️ Ràng Buộc Chung (Cả 5 Người)

### Yêu cầu BẮT BUỘC
1. ✅ Mỗi thành viên **PHẢI viết ít nhất 1 câu** trong Phần 2 (trigger/procedure/function).
2. ✅ Mọi thao tác CRUD trên app **PHẢI gọi stored procedure**, KHÔNG dùng raw SQL.
3. ✅ App **PHẢI KẾT NỐI THẬT** với CSDL — nếu không sẽ 0 điểm phần App.
4. ✅ Mỗi người phải **nắm được nội dung** tất cả các phần (dù không phải phần mình làm).

### Điểm trừ cần tránh
1. ❌ Các hàm/thủ tục/trigger có **nội dung gần giống nhau**.
2. ❌ Dữ liệu chuẩn bị **quá ít hoặc không có ý nghĩa**.
3. ❌ Thành viên **không hiểu** phần người khác làm.
4. ❌ Ràng buộc CHECK được thì **không dùng trigger** thay.

---

## 🔗 Kết Nối Dữ Liệu Giữa Các Phần

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

> **Tip:** Thống nhất **cấu trúc response API** trước khi code: `{ success: boolean, data: [...], message: string }`. Tránh phải sửa khi ghép.

---

## 📆 Timeline Gợi Ý

| Ngày | P1 | P2 | P3 | P4 | P5 |
|------|----|----|----|----|-----|
| 1–2 | DDL 17 bảng + constraints | Chuẩn bị dữ liệu mẫu | Đọc hiểu chuỗi trigger dẫn xuất | Thiết kế 2 thủ tục truy vấn | Setup backend + kết nối DB |
| 2–3 | Viết trigger RBND | Viết 3 CRUD procedures | Viết 2 trigger dẫn xuất | Code 2 thủ tục truy vấn | Viết 2 functions |
| 3–4 | Test DDL + trigger | Test CRUD + fix data | Code CRUD screen | Code list screen | Tạo API routes |
| 4–5 | Cả team ghép: Backend ↔ App → test end-to-end → fix bugs |
| 5–6 | Cả team: viết báo cáo + chuẩn bị demo + rehearsal trình bày |

---

## ⚙️ Quy ước chung

1. **Khóa Database (Freeze DB):** Sau khi P1 hoàn thành Phase 1, chốt cấu trúc Database. Bất kỳ ai muốn đổi tên cột, thêm bảng phải thông báo cả nhóm.
2. **Quy tắc đặt tên:**
   * Thủ tục (Proc): Tiền tố `sp_` (VD: `sp_ThemMonAn`).
   * Hàm (Func): Tiền tố `fn_` (VD: `fn_TinhDoanhThu`).
   * Trigger: Tiền tố `trg_` (VD: `trg_CapNhatDoanhThu`).
3. **Quản lý Source Code:** Cập nhật file SQL theo thứ tự:
   * `01_create_tables.sql` (P1)
   * `02_sample_data.sql` (P2)
   * `03_procedures_crud.sql` (P2)
   * `04_triggers.sql` (P1 + P3)
   * `05_procedures_query.sql` (P4)
   * `06_functions.sql` (P5)
4. **Viết Comment:** Mỗi đoạn code SQL phải ghi rõ:
   * Chức năng làm gì.
   * Ai là người viết (để chấm điểm chéo).
   * Sẵn lệnh `EXEC sp_TenThuTuc ...` để demo khi báo cáo.
