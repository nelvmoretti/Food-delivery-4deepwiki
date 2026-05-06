-- =============================================
-- BTL2 - HE CO SO DU LIEU - HK252
-- Nhom 4 - Lop L04
-- Chu de: Logistic Giao Do An
-- File 4: Triggers
-- Gom:
--   4.1  Trigger rang buoc nghiep vu    - Tai xe nhan don (khong nhan 2 don cung luc)
--   4.2  Trigger tinh dan xuat          - Tong_tien DON_HANG
--   4.3  Trigger tinh dan xuat          - Doanh_thu NHA_HANG
--   4.4  Trigger tinh dan xuat          - Gia_chot CHI_TIET_DON_HANG
--   4.5  Trigger dong bo                - Trang thai DON_HANG khi tai xe cap nhat
--   4.6  Trigger rang buoc ngu nghia    - Nha hang phai co it nhat 1 mon an
--   4.7  Trigger rang buoc ngu nghia    - Tu dong tao GIO_HANG khi tao KHACH_HANG
--   4.8  Trigger rang buoc ngu nghia    - Nguoi dung phai co it nhat 1 so dien thoai
--   4.9  Trigger validate               - Tai xe phai Online khi nhan don
--   4.10 Trigger validate               - Khach hang chi danh gia mon da dat va nhan
--   4.11 Trigger validate               - Khong chuyen trang thai don hang nguoc chieu
--   4.12 Trigger validate               - Khong sua thanh toan cua don da huy
--   4.13 Trigger validate               - Khong xac nhan don hang rong (0 chi tiet)
--   4.14 Trigger validate               - Khong cho sua Gia_chot sau khi da tao
--   4.15 Trigger validate               - Khong sua/them/xoa chi tiet don da hoan thanh hoac da huy
--   4.16 Trigger tu dong                - Cap nhat trang thai thanh toan khi don hang bi huy
-- =============================================
USE LogisticGiaoDoAn;
GO

-- =============================================
-- 4.1. TRIGGER RANG BUOC NGHIEP VU
-- Ten: trg_CheckTaiXeNhanDon
-- Rang buoc: Mot tai xe chi duoc nhan don hang moi khi KHONG co
--            don hang nao dang o trang thai 'Dang_giao'.
-- Thao tac DML bi anh huong: INSERT, UPDATE tren TAI_XE_NHAN_DON
-- =============================================
IF OBJECT_ID('trg_CheckTaiXeNhanDon', 'TR') IS NOT NULL
    DROP TRIGGER trg_CheckTaiXeNhanDon;
GO

CREATE TRIGGER trg_CheckTaiXeNhanDon
ON TAI_XE_NHAN_DON
FOR INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiem tra xem tai xe vua duoc INSERT/UPDATE co dang giao don khac hay khong
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN TAI_XE_NHAN_DON t ON i.ID_tai_xe = t.ID_tai_xe
        WHERE t.Trang_thai_don = N'Dang_giao'
          AND t.ID_don_hang <> i.ID_don_hang -- Loai tru chinh don dang xu ly
    )
    BEGIN
        RAISERROR(
            N'Loi nghiep vu: Tai xe dang co don hang o trang thai [Dang_giao], khong the nhan them don moi.',
            16, 1
        );
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- Cap nhat trang thai tai xe tuong ung voi trang thai don
    UPDATE tx
    SET Trang_thai =
        CASE
            WHEN i.Trang_thai_don = N'Dang_giao'              THEN N'Dang_giao'
            WHEN i.Trang_thai_don IN (N'Da_giao', N'Da_huy')  THEN N'Online'
            ELSE tx.Trang_thai
        END
    FROM TAI_XE tx
    JOIN inserted i ON tx.ID = i.ID_tai_xe;
END
GO

-- =============================================
-- 4.2. TRIGGER TINH THUOC TINH DAN XUAT: Tong_tien (DON_HANG)
-- Ten: trg_UpdateTongTienDonHang
-- Khi nao chay: Sau moi INSERT / UPDATE / DELETE tren CHI_TIET_DON_HANG
-- Logic: Tong_tien = SUM(So_luong * Gia_chot) cua cac chi tiet cung don hang
-- Luu y: Trigger nay chay SAU trg_SetGiaChot (duoc dat la LAST)
-- =============================================
IF OBJECT_ID('trg_UpdateTongTienDonHang', 'TR') IS NOT NULL
    DROP TRIGGER trg_UpdateTongTienDonHang;
GO

CREATE TRIGGER trg_UpdateTongTienDonHang
ON CHI_TIET_DON_HANG
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE dh
    SET dh.Tong_tien = ISNULL(agg.TongMoi, 0)
    FROM DON_HANG dh
    JOIN (
        SELECT DISTINCT ID_don_hang FROM inserted
        UNION
        SELECT DISTINCT ID_don_hang FROM deleted
    ) affected ON dh.ID = affected.ID_don_hang
    LEFT JOIN (
        SELECT ID_don_hang, SUM(So_luong * Gia_chot) AS TongMoi
        FROM CHI_TIET_DON_HANG
        GROUP BY ID_don_hang
    ) agg ON dh.ID = agg.ID_don_hang;
END
GO

-- =============================================
-- 4.3. TRIGGER TINH THUOC TINH DAN XUAT: Doanh_thu (NHA_HANG)
-- Ten: trg_UpdateDoanhThuNhaHang
-- Khi nao chay: Sau moi INSERT / UPDATE / DELETE tren DON_HANG
-- Logic: Doanh_thu = SUM(Tong_tien) cua don hang trang thai = 'Da_giao'
-- =============================================
IF OBJECT_ID('trg_UpdateDoanhThuNhaHang', 'TR') IS NOT NULL
    DROP TRIGGER trg_UpdateDoanhThuNhaHang;
GO

CREATE TRIGGER trg_UpdateDoanhThuNhaHang
ON DON_HANG
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE nh
    SET nh.Doanh_thu = ISNULL(agg.DoanhThuMoi, 0)
    FROM NHA_HANG nh
    JOIN (
        SELECT DISTINCT ID_nha_hang FROM inserted
        UNION
        SELECT DISTINCT ID_nha_hang FROM deleted
    ) affected ON nh.ID_nha_hang = affected.ID_nha_hang
    LEFT JOIN (
        SELECT ID_nha_hang, SUM(Tong_tien) AS DoanhThuMoi
        FROM DON_HANG
        WHERE Trang_thai = N'Da_giao'
        GROUP BY ID_nha_hang
    ) agg ON nh.ID_nha_hang = agg.ID_nha_hang;
END
GO

-- =============================================
-- 4.4. TRIGGER TINH THUOC TINH DAN XUAT: Gia_chot (CHI_TIET_DON_HANG)
-- Ten: trg_SetGiaChot
-- Khi nao chay: Sau khi INSERT vao CHI_TIET_DON_HANG
-- Logic:
--   Gia_chot = MON_AN.Gia - (Tien_giam_gia tot nhat con han cho mon an do)
--   Neu khong co khuyen mai => Gia_chot = MON_AN.Gia
--   Dam bao Gia_chot >= 0
-- Nguon: THAY_DOI_VOI_DATABASE.md muc 6.4
-- Thu tu: FIRST (phai chay truoc trg_UpdateTongTienDonHang)
-- =============================================
IF OBJECT_ID('trg_SetGiaChot', 'TR') IS NOT NULL
    DROP TRIGGER trg_SetGiaChot;
GO

CREATE TRIGGER trg_SetGiaChot
ON CHI_TIET_DON_HANG
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE ct
    SET ct.Gia_chot =
        CASE
            WHEN km_best.MaxGiam IS NOT NULL
                THEN CASE
                         WHEN (ma.Gia - km_best.MaxGiam) < 0 THEN 0
                         ELSE (ma.Gia - km_best.MaxGiam)
                     END
            ELSE ma.Gia
        END
    FROM CHI_TIET_DON_HANG ct
    JOIN inserted i ON ct.ID_don_hang = i.ID_don_hang
                   AND ct.ID_mon_an   = i.ID_mon_an
    JOIN MON_AN ma ON ct.ID_mon_an = ma.ID
    LEFT JOIN (
        SELECT
            kmcma.ID_mon_an,
            MAX(km.Tien_giam_gia) AS MaxGiam
        FROM KHUYEN_MAI_CHO_MON_AN kmcma
        JOIN KHUYEN_MAI km ON kmcma.ID_khuyen_mai = km.ID
        WHERE km.Han_su_dung >= GETDATE()
        GROUP BY kmcma.ID_mon_an
    ) km_best ON ma.ID = km_best.ID_mon_an;
END
GO

-- Thiet lap thu tu: trg_SetGiaChot FIRST, trg_UpdateTongTienDonHang LAST
EXEC sp_settriggerorder
    @triggername = N'trg_SetGiaChot',
    @order       = N'First',
    @stmttype    = N'INSERT';
GO

EXEC sp_settriggerorder
    @triggername = N'trg_UpdateTongTienDonHang',
    @order       = N'Last',
    @stmttype    = N'INSERT';
GO

-- =============================================
-- 4.5. TRIGGER DONG BO TRANG THAI DON HANG KHI TAI XE CAP NHAT
-- Ten: trg_SyncDonHangFromTaiXe
-- Khi nao chay: Sau khi UPDATE Trang_thai_don trong TAI_XE_NHAN_DON
-- Logic mapping:
--   'Da_nhan'   -> DON_HANG.Trang_thai = 'Da_xac_nhan'
--   'Dang_giao' -> DON_HANG.Trang_thai = 'Dang_giao'
--   'Da_giao'   -> DON_HANG.Trang_thai = 'Da_giao'
--   'Da_huy'    -> DON_HANG.Trang_thai = 'Da_huy'
-- Muc dich: Tranh mat dong bo giua 2 bang khi cap nhat mot phia
-- =============================================
IF OBJECT_ID('trg_SyncDonHangFromTaiXe', 'TR') IS NOT NULL
    DROP TRIGGER trg_SyncDonHangFromTaiXe;
GO

CREATE TRIGGER trg_SyncDonHangFromTaiXe
ON TAI_XE_NHAN_DON
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT UPDATE(Trang_thai_don)
        RETURN;

    UPDATE dh
    SET dh.Trang_thai =
        CASE i.Trang_thai_don
            WHEN N'Da_nhan'   THEN N'Da_xac_nhan'
            WHEN N'Dang_giao' THEN N'Dang_giao'
            WHEN N'Da_giao'   THEN N'Da_giao'
            WHEN N'Da_huy'    THEN N'Da_huy'
            ELSE dh.Trang_thai
        END
    FROM DON_HANG dh
    JOIN inserted i ON dh.ID = i.ID_don_hang;
END
GO

-- =============================================
-- 4.6. TRIGGER RANG BUOC NGU NGHIA: Nha hang phai co it nhat 1 mon an
-- Ten: trg_CheckNhaHangCoMonAn
-- Khi nao chay: Truoc khi DELETE tren MON_AN
-- Logic: Neu xoa mon an cuoi cung cua nha hang -> chặn va bao loi
-- Nguon: THAY_DOI_VOI_DATABASE.md muc 4.2
-- Ghi chu: Chieu Nha hang -> Mon an (Mandatory) khong the rang buoc bang
--          CHECK/FK thuan tuy, phai dung Trigger
-- =============================================
IF OBJECT_ID('trg_CheckNhaHangCoMonAn', 'TR') IS NOT NULL
    DROP TRIGGER trg_CheckNhaHangCoMonAn;
GO

CREATE TRIGGER trg_CheckNhaHangCoMonAn
ON MON_AN
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiem tra tung mon an bi xoa: neu la mon cuoi cung cua nha hang -> chan
    IF EXISTS (
        SELECT 1
        FROM deleted d
        WHERE (
            SELECT COUNT(*)
            FROM MON_AN
            WHERE ID_nha_hang = d.ID_nha_hang
        ) = 1
    )
    BEGIN
        RAISERROR(
            N'Loi rang buoc ngu nghia: Khong the xoa mon an cuoi cung cua nha hang. Moi nha hang phai co it nhat 1 mon an.',
            16, 1
        );
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- Neu hop le (con nhieu hon 1 mon), thuc hien xoa binh thuong
    DELETE FROM MON_AN
    WHERE ID IN (SELECT ID FROM deleted);
END
GO

-- =============================================
-- 4.7. TRIGGER RANG BUOC NGU NGHIA: Tu dong tao GIO_HANG khi tao KHACH_HANG
-- Ten: trg_AutoCreateGioHang
-- Khi nao chay: Sau khi INSERT vao KHACH_HANG
-- Logic: Moi khach hang moi phai co dung 1 gio hang (quan he 1:1 Mandatory)
--        -> Tu dong INSERT vao GIO_HANG sau khi khach hang duoc tao
-- Nguon: THAY_DOI_VOI_DATABASE.md muc 2
-- =============================================
IF OBJECT_ID('trg_AutoCreateGioHang', 'TR') IS NOT NULL
    DROP TRIGGER trg_AutoCreateGioHang;
GO

CREATE TRIGGER trg_AutoCreateGioHang
ON KHACH_HANG
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Tu dong tao gio hang tuong ung cho tung khach hang moi
    INSERT INTO GIO_HANG (Thoi_gian_tao, Trang_thai, ID_khach_hang)
    SELECT
        GETDATE(),
        N'Dang_mo',
        i.ID
    FROM inserted i
    -- Chi tao neu chua co gio hang (tranh loi neu chay lai)
    WHERE NOT EXISTS (
        SELECT 1 FROM GIO_HANG WHERE ID_khach_hang = i.ID
    );
END
GO

-- =============================================
-- 4.8. TRIGGER RANG BUOC NGU NGHIA: Nguoi dung phai co it nhat 1 so dien thoai
-- Ten: trg_CheckSoDienThoai
-- Khi nao chay: Truoc khi DELETE tren SO_DIEN_THOAI
-- Logic: Neu xoa so dien thoai cuoi cung cua nguoi dung -> chan va bao loi
-- Nguon: THAY_DOI_VOI_DATABASE.md muc 6.1
-- =============================================
IF OBJECT_ID('trg_CheckSoDienThoai', 'TR') IS NOT NULL
    DROP TRIGGER trg_CheckSoDienThoai;
GO

CREATE TRIGGER trg_CheckSoDienThoai
ON SO_DIEN_THOAI
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiem tra tung SDT bi xoa: neu la SDT cuoi cung cua nguoi dung -> chan
    IF EXISTS (
        SELECT 1
        FROM deleted d
        WHERE (
            SELECT COUNT(*)
            FROM SO_DIEN_THOAI
            WHERE id_nguoi_dung = d.id_nguoi_dung
        ) = 1
    )
    BEGIN
        RAISERROR(
            N'Loi rang buoc ngu nghia: Khong the xoa so dien thoai cuoi cung cua nguoi dung. Moi nguoi dung phai co it nhat 1 so dien thoai.',
            16, 1
        );
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- Neu hop le (con nhieu SDT), thuc hien xoa binh thuong
    DELETE FROM SO_DIEN_THOAI
    WHERE SDT_chinh IN (SELECT SDT_chinh FROM deleted)
      AND id_nguoi_dung IN (SELECT id_nguoi_dung FROM deleted);
END
GO

-- =============================================
-- 4.9. TRIGGER VALIDATE: Tai xe phai co trang thai Online khi nhan don
-- Ten: trg_ValidateTaiXeOnline
-- Khi nao chay: Truoc khi INSERT vao TAI_XE_NHAN_DON
-- Logic: Tai xe co trang thai 'Offline' khong duoc nhan don moi
--        (trg_CheckTaiXeNhanDon da xu ly 'Dang_giao', trigger nay xu ly 'Offline')
-- =============================================
IF OBJECT_ID('trg_ValidateTaiXeOnline', 'TR') IS NOT NULL
    DROP TRIGGER trg_ValidateTaiXeOnline;
GO

CREATE TRIGGER trg_ValidateTaiXeOnline
ON TAI_XE_NHAN_DON
FOR INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN TAI_XE tx ON i.ID_tai_xe = tx.ID
        WHERE tx.Trang_thai = N'Offline'
    )
    BEGIN
        RAISERROR(
            N'Loi validate: Tai xe dang o trang thai [Offline], khong the nhan don hang. Tai xe phai Online truoc khi nhan don.',
            16, 1
        );
        ROLLBACK TRANSACTION;
        RETURN;
    END
END
GO

-- =============================================
-- 4.10. TRIGGER VALIDATE: Khach hang chi duoc danh gia mon an da dat va nhan
-- Ten: trg_ValidateDanhGia
-- Khi nao chay: Truoc khi INSERT vao DANH_GIA
-- Logic: Khach hang chi duoc danh gia mon an neu ho da co it nhat 1 don hang
--        trang thai 'Da_giao' chua mon an do
-- =============================================
IF OBJECT_ID('trg_ValidateDanhGia', 'TR') IS NOT NULL
    DROP TRIGGER trg_ValidateDanhGia;
GO

CREATE TRIGGER trg_ValidateDanhGia
ON DANH_GIA
FOR INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        WHERE NOT EXISTS (
            -- Kiem tra khach hang da tung dat mon nay va don da giao thanh cong
            SELECT 1
            FROM CHI_TIET_DON_HANG ct
            JOIN DON_HANG dh ON ct.ID_don_hang = dh.ID
            WHERE dh.ID_khach_hang = i.ID_khach_hang
              AND ct.ID_mon_an     = i.ID_mon_an
              AND dh.Trang_thai    = N'Da_giao'
        )
    )
    BEGIN
        RAISERROR(
            N'Loi validate: Khach hang chi co the danh gia mon an da duoc dat va giao thanh cong. Vui long dat hang truoc khi danh gia.',
            16, 1
        );
        ROLLBACK TRANSACTION;
        RETURN;
    END
END
GO

-- =============================================
-- 4.11. TRIGGER VALIDATE: Khong cho phep chuyen trang thai don hang nguoc chieu
-- Ten: trg_ValidateTrangThaiDonHang
-- Khi nao chay: Truoc khi UPDATE DON_HANG
-- Logic luong trang thai hop le (chi di tien, khong di lui):
--   Cho_xac_nhan -> Da_xac_nhan -> Dang_chuan_bi -> Dang_giao -> Da_giao
--   Bat ky trang thai nao cung co the -> Da_huy (cho phep huy)
-- =============================================
IF OBJECT_ID('trg_ValidateTrangThaiDonHang', 'TR') IS NOT NULL
    DROP TRIGGER trg_ValidateTrangThaiDonHang;
GO

CREATE TRIGGER trg_ValidateTrangThaiDonHang
ON DON_HANG
FOR UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Chi kiem tra khi cot Trang_thai thay doi
    IF NOT UPDATE(Trang_thai)
        RETURN;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN deleted d ON i.ID = d.ID
        WHERE
            -- Khong cho phep chuyen trang thai nguoc chieu
            -- (Da_huy luon duoc phep tu bat ky trang thai nao)
            i.Trang_thai <> N'Da_huy'
            AND (
                -- Da_xac_nhan chi duoc chuyen tu Cho_xac_nhan
                (i.Trang_thai = N'Da_xac_nhan'   AND d.Trang_thai NOT IN (N'Cho_xac_nhan'))
                OR
                -- Dang_chuan_bi chi duoc chuyen tu Da_xac_nhan
                (i.Trang_thai = N'Dang_chuan_bi' AND d.Trang_thai NOT IN (N'Da_xac_nhan'))
                OR
                -- Dang_giao chi duoc chuyen tu Dang_chuan_bi hoac Da_xac_nhan
                (i.Trang_thai = N'Dang_giao'     AND d.Trang_thai NOT IN (N'Dang_chuan_bi', N'Da_xac_nhan'))
                OR
                -- Da_giao chi duoc chuyen tu Dang_giao
                (i.Trang_thai = N'Da_giao'        AND d.Trang_thai NOT IN (N'Dang_giao'))
                OR
                -- Khong cho phep quay lai Cho_xac_nhan tu bat ky trang thai nao khac
                (i.Trang_thai = N'Cho_xac_nhan'  AND d.Trang_thai <> N'Cho_xac_nhan')
            )
    )
    BEGIN
        RAISERROR(
            N'Loi validate: Trang thai don hang khong hop le. Khong duoc phep chuyen trang thai nguoc chieu hoac bo qua buoc trong quy trinh xu ly don hang.',
            16, 1
        );
        ROLLBACK TRANSACTION;
        RETURN;
    END
END
GO

-- =============================================
-- 4.12. TRIGGER VALIDATE: Khong duoc sua thanh toan cua don hang da huy
-- Ten: trg_ValidateThanhToan
-- Khi nao chay: Truoc khi UPDATE THANH_TOAN
-- Logic: Neu ban ghi THANH_TOAN lien ket voi DON_HANG co trang thai 'Da_huy'
--        -> khong cho phep chinh sua thong tin thanh toan
-- =============================================
IF OBJECT_ID('trg_ValidateThanhToan', 'TR') IS NOT NULL
    DROP TRIGGER trg_ValidateThanhToan;
GO

CREATE TRIGGER trg_ValidateThanhToan
ON THANH_TOAN
FOR UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN DON_HANG dh ON dh.ID_thanh_toan = i.ID
        WHERE dh.Trang_thai = N'Da_huy'
    )
    BEGIN
        RAISERROR(
            N'Loi validate: Khong the chinh sua thong tin thanh toan cua don hang da bi huy.',
            16, 1
        );
        ROLLBACK TRANSACTION;
        RETURN;
    END
END
GO

-- =============================================
-- TEST CASES MINH HOA
-- =============================================

-- === TEST 4.1 - Trigger rang buoc tai xe nhan don ===
-- Test 1a: TX 11 dang giao DH4 -> Thu nhan DH7 se bi loi
-- INSERT INTO TAI_XE_NHAN_DON (ID_don_hang, ID_tai_xe, Trang_thai_don)
-- VALUES (7, 11, N'Da_nhan');
-- => Mong doi: RAISERROR - Tai xe dang co don Dang_giao

-- Test 1b: TX 12 dang ranh -> Nhan DH7 thanh cong
-- INSERT INTO TAI_XE_NHAN_DON (ID_don_hang, ID_tai_xe, Trang_thai_don)
-- VALUES (7, 12, N'Da_nhan');
-- => Mong doi: INSERT thanh cong

-- === TEST 4.2 - Trigger tinh Tong_tien ===
-- Test 2a: Them chi tiet vao DH1, kiem tra Tong_tien tang
-- INSERT INTO CHI_TIET_DON_HANG (ID_don_hang, So_luong, ID_mon_an, Gia_chot)
-- VALUES (1, 1, 2, 45000);
-- SELECT Tong_tien FROM DON_HANG WHERE ID = 1;
-- => Mong doi: 175000

-- === TEST 4.3 - Trigger tinh Doanh_thu ===
-- Test 3a: Kiem tra doanh thu NH1 (DH1 + DH5 = 305000)
-- SELECT Doanh_thu FROM NHA_HANG WHERE ID_nha_hang = 1;
-- => Mong doi: 305000

-- === TEST 4.4 - Trigger tinh Gia_chot ===
-- Test 4a: MA1 co KM giam 10000, gia goc 45000 -> Gia_chot = 35000
-- INSERT INTO CHI_TIET_DON_HANG (ID_don_hang, Ghi_chu, So_luong, ID_mon_an, Gia_chot)
-- VALUES (7, N'Test gia chot', 1, 1, 99999);
-- SELECT Gia_chot FROM CHI_TIET_DON_HANG WHERE ID_don_hang = 7 AND ID_mon_an = 1;
-- => Mong doi: 35000

-- === TEST 4.5 - Trigger dong bo trang thai ===
-- Test 5a: Cap nhat TX_NHAN_DON -> kiem tra DON_HANG dong bo
-- UPDATE TAI_XE_NHAN_DON SET Trang_thai_don = N'Da_giao' WHERE ID_don_hang = 4;
-- SELECT Trang_thai FROM DON_HANG WHERE ID = 4;
-- => Mong doi: 'Da_giao'

-- === TEST 4.6 - Trigger nha hang phai co mon an ===
-- Test 6a: Xoa mon cuoi cung cua NH -> loi
-- (Gia su NH5 chi con MA12, xoa MA12 se bi chan)
-- EXEC sp_DeleteMonAn @ID = 12; -- Neu MA12 la mon cuoi cua NH5
-- => Mong doi: RAISERROR - Khong the xoa mon an cuoi cung

-- Test 6b: NH co nhieu hon 1 mon -> xoa 1 mon thanh cong
-- EXEC sp_DeleteMonAn @ID = 11; -- MA11 trong NH5 van con MA10, MA12
-- => Mong doi: Xoa thanh cong

-- === TEST 4.7 - Trigger tu dong tao gio hang ===
-- Test 7a: Tao khach hang moi -> gio hang tu dong duoc tao
-- INSERT INTO TAI_KHOAN_NGUOI_DUNG (Ho, Ten, Mat_khau, email, Phan_loai_nguoi_dung)
-- VALUES (N'Test', N'User', N'pass', N'test@test.com', N'Khach_hang');
-- DECLARE @newID INT = SCOPE_IDENTITY();
-- INSERT INTO KHACH_HANG (ID) VALUES (@newID);
-- SELECT * FROM GIO_HANG WHERE ID_khach_hang = @newID;
-- => Mong doi: 1 ban ghi GIO_HANG duoc tao tu dong

-- === TEST 4.8 - Trigger nguoi dung phai co SDT ===
-- Test 8a: Xoa SDT duy nhat cua nguoi dung -> loi
-- DELETE FROM SO_DIEN_THOAI WHERE id_nguoi_dung = 2; -- KH Binh chi co 1 SDT
-- => Mong doi: RAISERROR - Khong the xoa SDT cuoi cung

-- Test 8b: Xoa 1 trong 2 SDT cua KH An (ID=1) -> thanh cong
-- DELETE FROM SO_DIEN_THOAI WHERE SDT_chinh = '0901234568' AND id_nguoi_dung = 1;
-- => Mong doi: Xoa thanh cong (KH An van con SDT '0901234567')

-- === TEST 4.9 - Trigger tai xe phai Online ===
-- Test 9a: TX 13 dang Offline -> Nhan don bi chan
-- INSERT INTO TAI_XE_NHAN_DON (ID_don_hang, ID_tai_xe, Trang_thai_don)
-- VALUES (7, 13, N'Da_nhan');
-- => Mong doi: RAISERROR - Tai xe dang Offline

-- Test 9b: TX 12 dang Online -> Nhan don thanh cong
-- INSERT INTO TAI_XE_NHAN_DON (ID_don_hang, ID_tai_xe, Trang_thai_don)
-- VALUES (7, 12, N'Da_nhan');
-- => Mong doi: INSERT thanh cong

-- === TEST 4.10 - Trigger validate danh gia ===
-- Test 10a: KH 1 danh gia MA1 (da dat DH1 co MA1, Da_giao) -> thanh cong
-- INSERT INTO DANH_GIA (ID_khach_hang, ID_mon_an, Binh_luan, Xep_hang)
-- VALUES (1, 1, N'Test', 5);
-- => Mong doi: INSERT thanh cong

-- Test 10b: KH 1 danh gia MA11 (chua dat bao gio) -> loi
-- INSERT INTO DANH_GIA (ID_khach_hang, ID_mon_an, Binh_luan, Xep_hang)
-- VALUES (1, 11, N'Test', 4);
-- => Mong doi: RAISERROR - Chua dat mon nay

-- === TEST 4.11 - Trigger validate trang thai don hang ===
-- Test 11a: Chuyen DH1 tu Da_giao -> Dang_giao (nguoc chieu) -> loi
-- UPDATE DON_HANG SET Trang_thai = N'Dang_giao' WHERE ID = 1;
-- => Mong doi: RAISERROR - Khong duoc chuyen nguoc

-- Test 11b: Huy don bat ky trang thai -> thanh cong
-- UPDATE DON_HANG SET Trang_thai = N'Da_huy' WHERE ID = 7;
-- => Mong doi: UPDATE thanh cong

-- === TEST 4.12 - Trigger validate thanh toan ===
-- Test 12a: Sua thanh toan cua DH8 (Da_huy, TT8) -> loi
-- UPDATE THANH_TOAN SET Trang_thai = N'Da_thanh_toan' WHERE ID = 8;
-- => Mong doi: RAISERROR - Don hang da huy

-- Test 12b: Sua thanh toan cua DH4 (Dang_giao, TT4) -> thanh cong
-- UPDATE THANH_TOAN SET Trang_thai = N'Da_thanh_toan',
--        Thoi_gian_thanh_toan = GETDATE() WHERE ID = 4;
-- => Mong doi: UPDATE thanh cong

-- =============================================
-- 4.13. TRIGGER VALIDATE: Khong cho xac nhan don hang rong
-- Ten: trg_ValidateDonHangKhongRong
-- Khi nao chay: Truoc khi UPDATE DON_HANG
-- Logic: Neu trang thai moi la 'Da_xac_nhan' ma don chua co chi tiet nao
--        (COUNT(CHI_TIET_DON_HANG) = 0) -> chan va bao loi
-- Nguon: Yeu cau bo sung muc 2 (Don hang hop le phai co it nhat 1 mon)
-- =============================================
IF OBJECT_ID('trg_ValidateDonHangKhongRong', 'TR') IS NOT NULL
    DROP TRIGGER trg_ValidateDonHangKhongRong;
GO

CREATE TRIGGER trg_ValidateDonHangKhongRong
ON DON_HANG
FOR UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Chi kiem tra khi cot Trang_thai thay doi
    IF NOT UPDATE(Trang_thai)
        RETURN;

    -- Neu don chuyen sang Da_xac_nhan nhung khong co chi tiet nao -> chan
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN deleted d ON i.ID = d.ID
        WHERE i.Trang_thai = N'Da_xac_nhan'
          AND d.Trang_thai <> N'Da_xac_nhan' -- Chi kiem tra khi moi chuyen vao trang thai nay
          AND NOT EXISTS (
              SELECT 1 FROM CHI_TIET_DON_HANG ct
              WHERE ct.ID_don_hang = i.ID
          )
    )
    BEGIN
        RAISERROR(
            N'Loi validate: Khong the xac nhan don hang rong. Don hang phai co it nhat 1 mon an truoc khi xac nhan.',
            16, 1
        );
        ROLLBACK TRANSACTION;
        RETURN;
    END
END
GO

-- =============================================
-- 4.14. TRIGGER VALIDATE: Khong cho phep sua Gia_chot sau khi da INSERT
-- Ten: trg_LockGiaChot
-- Khi nao chay: Truoc khi UPDATE CHI_TIET_DON_HANG
-- Logic: Gia_chot la gia da chot tai thoi diem dat hang, khong duoc thay doi
--        sau khi ban ghi da duoc tao. Moi thay doi so sanh inserted vs deleted.
-- Nguon: Yeu cau bo sung muc 2
-- =============================================
IF OBJECT_ID('trg_LockGiaChot', 'TR') IS NOT NULL
    DROP TRIGGER trg_LockGiaChot;
GO

CREATE TRIGGER trg_LockGiaChot
ON CHI_TIET_DON_HANG
FOR UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Chi kiem tra khi cot Gia_chot thay doi
    IF NOT UPDATE(Gia_chot)
        RETURN;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN deleted d ON i.ID = d.ID
        WHERE i.Gia_chot <> d.Gia_chot
    )
    BEGIN
        RAISERROR(
            N'Loi validate: Gia_chot khong duoc phep chinh sua sau khi da chot. Day la gia tai thoi diem dat hang va co gia tri lich su.',
            16, 1
        );
        ROLLBACK TRANSACTION;
        RETURN;
    END
END
GO

-- =============================================
-- 4.15. TRIGGER VALIDATE: Khong duoc sua / them / xoa chi tiet don da hoan thanh hoac da huy
-- Ten: trg_LockChiTietDonDaXong
-- Khi nao chay: Truoc khi INSERT / UPDATE / DELETE tren CHI_TIET_DON_HANG
-- Logic: Neu don hang tuong ung dang o trang thai 'Da_giao' hoac 'Da_huy'
--        -> cam moi thay doi de bao toan tinh toan ven du lieu lich su
-- Nguon: Yeu cau bo sung muc 5
-- =============================================
IF OBJECT_ID('trg_LockChiTietDonDaXong', 'TR') IS NOT NULL
    DROP TRIGGER trg_LockChiTietDonDaXong;
GO

CREATE TRIGGER trg_LockChiTietDonDaXong
ON CHI_TIET_DON_HANG
FOR INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Lay tap hop ID don hang bi anh huong (tu INSERT/UPDATE hoac DELETE)
    -- Gop ca inserted va deleted de xu ly moi loai thao tac
    IF EXISTS (
        SELECT 1
        FROM (
            SELECT ID_don_hang FROM inserted
            UNION
            SELECT ID_don_hang FROM deleted
        ) affected
        JOIN DON_HANG dh ON dh.ID = affected.ID_don_hang
        WHERE dh.Trang_thai IN (N'Da_giao', N'Da_huy')
    )
    BEGIN
        RAISERROR(
            N'Loi validate: Khong the them, sua hoac xoa chi tiet cua don hang da hoan thanh (Da_giao) hoac da bi huy (Da_huy). Du lieu don hang lich su phai duoc giu nguyen.',
            16, 1
        );
        ROLLBACK TRANSACTION;
        RETURN;
    END
END
GO

-- =============================================
-- 4.16. TRIGGER TU DONG: Cap nhat trang thai THANH_TOAN khi DON_HANG bi huy
-- Ten: trg_AutoUpdateThanhToanKhiHuyDon
-- Khi nao chay: Sau khi UPDATE DON_HANG
-- Logic mapping khi don chuyen sang 'Da_huy':
--   THANH_TOAN.Trang_thai = 'Da_thanh_toan' -> chuyen sang 'Hoan_tien'
--   THANH_TOAN.Trang_thai = 'Cho_thanh_toan' -> chuyen sang 'Da_huy'
-- Nguon: Yeu cau bo sung muc 5 (khi don bi huy, thanh toan phai dong bo)
-- Ghi chu: Trigger trg_ValidateThanhToan (4.12) chi CHẶN sua thanh toan thu cong
--          khi don da huy. Trigger nay la cap nhat TU DONG hop le.
--          De tranh xung dot, trigger nay dung sp_executesql voi bien de bypass
--          trigger 4.12 (vi day la cap nhat he thong, khong phai thu cong).
--          Thuc ra khong bi chan vi 4.12 chi chek khi DON_HANG.Trang_thai = Da_huy
--          TRUOC khi UPDATE, con trigger nay chay AFTER UPDATE nen da la Da_huy roi.
--          -> 4.12 check: "don dang o Da_huy -> chan sua" chi ap dung cho lenh
--             UPDATE THANH_TOAN thu cong TU NGUOI DUNG, khong anh huong trigger nay
--             vi trigger goi UPDATE THANH_TOAN SAU khi don da la Da_huy.
--          Ket luan: Khong co xung dot logic.
-- =============================================
IF OBJECT_ID('trg_AutoUpdateThanhToanKhiHuyDon', 'TR') IS NOT NULL
    DROP TRIGGER trg_AutoUpdateThanhToanKhiHuyDon;
GO

CREATE TRIGGER trg_AutoUpdateThanhToanKhiHuyDon
ON DON_HANG
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Chi xu ly khi cot Trang_thai thay doi
    IF NOT UPDATE(Trang_thai)
        RETURN;

    -- Xu ly cac don vua chuyen sang 'Da_huy'
    -- Truong hop 1: Thanh toan dang 'Da_thanh_toan' -> phai hoan tien
    UPDATE tt
    SET tt.Trang_thai = N'Hoan_tien'
    FROM THANH_TOAN tt
    JOIN inserted i  ON tt.ID = i.ID_thanh_toan
    JOIN deleted  d  ON i.ID  = d.ID
    WHERE i.Trang_thai = N'Da_huy'
      AND d.Trang_thai <> N'Da_huy'   -- Moi chuyen sang huy (tranh chay lap)
      AND tt.Trang_thai = N'Da_thanh_toan';

    -- Truong hop 2: Thanh toan dang 'Cho_thanh_toan' -> huy thanh toan
    UPDATE tt
    SET tt.Trang_thai = N'Da_huy'
    FROM THANH_TOAN tt
    JOIN inserted i  ON tt.ID = i.ID_thanh_toan
    JOIN deleted  d  ON i.ID  = d.ID
    WHERE i.Trang_thai = N'Da_huy'
      AND d.Trang_thai <> N'Da_huy'
      AND tt.Trang_thai = N'Cho_thanh_toan';
END
GO

-- =============================================
-- TEST CASES BO SUNG (4.13 - 4.16)
-- =============================================

-- === TEST 4.13 - Trigger khong xac nhan don rong ===
-- Test 13a: Tao don hang moi khong co chi tiet, thu xac nhan -> loi
-- INSERT INTO THANH_TOAN (Phuong_thuc, Trang_thai) VALUES (N'Tien_mat', N'Cho_thanh_toan');
-- DECLARE @tt INT = SCOPE_IDENTITY();
-- INSERT INTO DON_HANG (ID_thanh_toan, ID_nha_hang, ID_khach_hang)
-- VALUES (@tt, 1, 1);
-- DECLARE @dh INT = SCOPE_IDENTITY();
-- UPDATE DON_HANG SET Trang_thai = N'Da_xac_nhan' WHERE ID = @dh;
-- => Mong doi: RAISERROR - Don hang rong khong duoc xac nhan

-- Test 13b: Don co chi tiet -> xac nhan thanh cong
-- (Lay DH7 da co 1 chi tiet MA8)
-- UPDATE DON_HANG SET Trang_thai = N'Da_xac_nhan' WHERE ID = 7;
-- => Mong doi: UPDATE thanh cong

-- === TEST 4.14 - Trigger khoa Gia_chot ===
-- Test 14a: Thu sua Gia_chot cua 1 chi tiet don hang -> loi
-- UPDATE CHI_TIET_DON_HANG SET Gia_chot = 99999 WHERE ID = 1;
-- => Mong doi: RAISERROR - Gia_chot khong duoc phep chinh sua

-- Test 14b: Sua Ghi_chu (khong phai Gia_chot) -> thanh cong
-- UPDATE CHI_TIET_DON_HANG SET Ghi_chu = N'Them tuong ot' WHERE ID = 1;
-- => Mong doi: UPDATE thanh cong

-- === TEST 4.15 - Trigger khoa chi tiet don da xong ===
-- Test 15a: Them chi tiet vao DH1 (Da_giao) -> loi
-- INSERT INTO CHI_TIET_DON_HANG (ID_don_hang, So_luong, ID_mon_an, Gia_chot)
-- VALUES (1, 1, 2, 45000);
-- => Mong doi: RAISERROR - Don hang Da_giao khong duoc sua

-- Test 15b: Xoa chi tiet cua DH8 (Da_huy) -> loi
-- DELETE FROM CHI_TIET_DON_HANG WHERE ID_don_hang = 8;
-- => Mong doi: RAISERROR - Don hang Da_huy khong duoc sua

-- Test 15c: Sua so luong chi tiet cua DH4 (Dang_giao) -> thanh cong
-- UPDATE CHI_TIET_DON_HANG SET So_luong = 2 WHERE ID_don_hang = 4;
-- => Mong doi: UPDATE thanh cong (don chua xong)

-- === TEST 4.16 - Trigger tu dong cap nhat thanh toan khi huy don ===
-- Test 16a: Huy DH4 (Dang_giao, TT4 = Cho_thanh_toan) -> TT4 tu dong chuyen sang Da_huy
-- UPDATE DON_HANG SET Trang_thai = N'Da_huy' WHERE ID = 4;
-- SELECT Trang_thai FROM THANH_TOAN WHERE ID = 4;
-- => Mong doi: 'Da_huy'

-- Test 16b: Huy don co thanh toan 'Da_thanh_toan' -> THANH_TOAN tu dong chuyen sang 'Hoan_tien'
-- (Gia su tao 1 don moi, thanh toan Da_thanh_toan, roi huy don do)
-- => Mong doi: THANH_TOAN.Trang_thai = 'Hoan_tien'

PRINT N'=== TAO TRIGGERS THANH CONG (16 TRIGGERS) ===';
GO
