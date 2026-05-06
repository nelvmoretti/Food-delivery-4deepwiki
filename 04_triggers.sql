-- =============================================
-- BTL2 - HE CO SO DU LIEU - HK252
-- Nhom 4 - Lop L04
-- Chu de: Logistic Giao Do An
-- File 4: Triggers
-- Gom:
--   4.1 Trigger rang buoc nghiep vu - Tai xe nhan don
--   4.2 Trigger tinh thuoc tinh dan xuat - Tong_tien DON_HANG
--   4.3 Trigger tinh thuoc tinh dan xuat - Doanh_thu NHA_HANG
--   4.4 Trigger tinh thuoc tinh dan xuat - Gia_chot CHI_TIET_DON_HANG (BO SUNG)
--   4.5 Trigger dong bo trang thai don hang khi tai xe cap nhat (BO SUNG)
-- =============================================
USE LogisticGiaoDoAn;
GO

-- =============================================
-- 4.1. TRIGGER RANG BUOC NGHIEP VU
-- Ten: trg_CheckTaiXeNhanDon
-- Rang buoc: Mot tai xe chi duoc nhan don hang moi khi KHONG co
--            don hang nao dang o trang thai 'Dang_giao'.
-- Thao tac DML: INSERT, UPDATE tren TAI_XE_NHAN_DON
-- Ly do: Dam bao tai xe chi giao 1 don tai 1 thoi diem,
--        tranh truong hop tai xe nhan nhieu don cung luc.
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

    -- Kiem tra tai xe vua INSERT/UPDATE co dang giao don khac khong
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

    -- Dong bo trang thai tai xe theo trang thai don hang moi nhat
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
-- Luu y: Trigger nay chay TRUOC trg_UpdateDoanhThuNhaHang vi:
--        trg_UpdateDoanhThuNhaHang doc Tong_tien tu DON_HANG,
--        nen Tong_tien phai duoc cap nhat truoc.
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

    -- Cap nhat Tong_tien cho tat ca don hang bi anh huong trong 1 lan
    -- (xu ly ca truong hop INSERT/UPDATE nhieu dong cung luc)
    UPDATE dh
    SET dh.Tong_tien = ISNULL(agg.TongMoi, 0)
    FROM DON_HANG dh
    JOIN (
        -- Lay danh sach cac ID don hang bi anh huong (tu ca inserted va deleted)
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
-- Logic: Doanh_thu = SUM(Tong_tien) cua cac don hang co trang thai = 'Da_giao'
--        thuoc nha hang do
-- Luu y: Chi tinh don Da_giao, khong tinh don Da_huy / Dang_giao / Cho_xac_nhan
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

    -- Cap nhat Doanh_thu cho tat ca nha hang bi anh huong
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
-- 4.4. TRIGGER TINH THUOC TINH DAN XUAT: Gia_chot (CHI_TIET_DON_HANG) -- BO SUNG
-- Ten: trg_SetGiaChot
-- Khi nao chay: Sau khi INSERT vao CHI_TIET_DON_HANG
-- Logic:
--   Gia_chot = MON_AN.Gia - (Tien_giam_gia tot nhat dang con han cho mon an do)
--   Neu mon an khong co khuyen mai nao con han => Gia_chot = MON_AN.Gia
--   Dam bao Gia_chot >= 0 (tranh giam gia qua lon)
-- Ly do can them:
--   Theo THAY_DOI_VOI_DATABASE.md muc 6.4, Gia_chot la thuoc tinh dan xuat
--   nhung chua co trigger tu dong dien gia tri khi Insert.
-- Luu y ve thu tu trigger:
--   trg_SetGiaChot (chay truoc, cap nhat Gia_chot)
--   => trg_UpdateTongTienDonHang (chay sau, doc Gia_chot de tinh Tong_tien)
--   SQL Server thuc thi AFTER trigger theo thu tu: FIRST -> trigger thuong -> LAST
--   Dat trg_SetGiaChot la FIRST, trg_UpdateTongTienDonHang la LAST
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

    -- Cap nhat Gia_chot cho tung dong moi duoc insert
    -- Gia_chot = Gia goc - Khuyen mai tot nhat con han (neu co)
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
        -- Tim khuyen mai co tien giam cao nhat, con trong han su dung
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

-- Thiet lap thu tu thuc thi: trg_SetGiaChot chay TRUOC trg_UpdateTongTienDonHang
-- (chi co tac dung neu ca 2 trigger cung tren 1 bang va 1 thao tac INSERT)
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
-- 4.5. TRIGGER DONG BO TRANG THAI DON HANG KHI TAI XE CAP NHAT -- BO SUNG
-- Ten: trg_SyncDonHangFromTaiXe
-- Khi nao chay: Sau khi UPDATE trang thai trong TAI_XE_NHAN_DON
-- Logic:
--   Khi tai xe cap nhat Trang_thai_don -> tu dong cap nhat Trang_thai DON_HANG
--   'Da_nhan'   -> DON_HANG.Trang_thai = 'Da_xac_nhan'
--   'Dang_giao' -> DON_HANG.Trang_thai = 'Dang_giao'
--   'Da_giao'   -> DON_HANG.Trang_thai = 'Da_giao'
--   'Da_huy'    -> DON_HANG.Trang_thai = 'Da_huy'
-- Ly do can them:
--   Tranh truong hop DON_HANG.Trang_thai va TAI_XE_NHAN_DON.Trang_thai_don
--   bi mat dong bo khi cap nhat mot phia.
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

    -- Chi xu ly khi cot Trang_thai_don thuc su thay doi
    IF NOT UPDATE(Trang_thai_don)
        RETURN;

    UPDATE dh
    SET dh.Trang_thai =
        CASE i.Trang_thai_don
            WHEN N'Da_nhan'   THEN N'Da_xac_nhan'
            WHEN N'Dang_giao' THEN N'Dang_giao'
            WHEN N'Da_giao'   THEN N'Da_giao'
            WHEN N'Da_huy'    THEN N'Da_huy'
            ELSE dh.Trang_thai -- Giu nguyen neu khong khop
        END
    FROM DON_HANG dh
    JOIN inserted i ON dh.ID = i.ID_don_hang;
END
GO

-- =============================================
-- TEST CASES MINH HOA
-- Chay sau khi da chay 01_create_tables.sql va 02_sample_data.sql
-- =============================================

-- === TEST 4.1 - Trigger rang buoc tai xe nhan don ===

-- Test 1a: TX 11 dang giao DH4 (Dang_giao) -> Thu nhan DH7 se bi loi
-- INSERT INTO TAI_XE_NHAN_DON (ID_don_hang, ID_tai_xe, Trang_thai_don)
-- VALUES (7, 11, N'Da_nhan');
-- => Ket qua mong doi: RAISERROR - Tai xe dang co don Dang_giao

-- Test 1b: TX 12 dang ranh (tat ca don da Da_giao) -> Nhan DH7 thanh cong
-- INSERT INTO TAI_XE_NHAN_DON (ID_don_hang, ID_tai_xe, Trang_thai_don)
-- VALUES (7, 12, N'Da_nhan');
-- => Ket qua mong doi: INSERT thanh cong, TAI_XE.Trang_thai = 'Online'

-- Test 1c: Update trang thai TX12 don 7 -> Dang_giao, kiem tra trang thai TX
-- UPDATE TAI_XE_NHAN_DON SET Trang_thai_don = N'Dang_giao'
-- WHERE ID_don_hang = 7;
-- => Ket qua mong doi: TAI_XE.Trang_thai cua TX12 = 'Dang_giao'

-- === TEST 4.2 - Trigger tinh Tong_tien don hang ===

-- Test 2a: Kiem tra Tong_tien DH1 hien tai
-- SELECT ID, Tong_tien FROM DON_HANG WHERE ID = 1;
-- => Mong doi: 130000 (2*45000 + 1*40000)

-- Test 2b: Them chi tiet vao DH1, kiem tra Tong_tien tu dong tang
-- INSERT INTO CHI_TIET_DON_HANG (ID_don_hang, So_luong, ID_mon_an, Gia_chot)
-- VALUES (1, 1, 2, 45000); -- Them 1 Pho bo chin
-- SELECT ID, Tong_tien FROM DON_HANG WHERE ID = 1;
-- => Mong doi: 175000 (130000 + 45000)

-- Test 2c: Xoa chi tiet vua them, kiem tra Tong_tien giam lai
-- DELETE FROM CHI_TIET_DON_HANG WHERE ID_don_hang = 1 AND ID_mon_an = 2;
-- SELECT ID, Tong_tien FROM DON_HANG WHERE ID = 1;
-- => Mong doi: 130000 (quay lai gia tri cu)

-- === TEST 4.3 - Trigger tinh Doanh_thu nha hang ===

-- Test 3a: Kiem tra doanh thu NHA_HANG 1 hien tai
-- SELECT ID_nha_hang, Ten, Doanh_thu FROM NHA_HANG WHERE ID_nha_hang = 1;
-- => Mong doi: 305000 (DH1: 130000 + DH5: 175000, ca hai Da_giao tai NH1)

-- Test 3b: Doi trang thai DH5 tu Da_giao sang Da_huy, doanh thu NH1 giam
-- UPDATE DON_HANG SET Trang_thai = N'Da_huy' WHERE ID = 5;
-- SELECT Doanh_thu FROM NHA_HANG WHERE ID_nha_hang = 1;
-- => Mong doi: 130000 (chi con DH1)

-- Test 3c: Khoi phuc lai
-- UPDATE DON_HANG SET Trang_thai = N'Da_giao' WHERE ID = 5;

-- === TEST 4.4 - Trigger tinh Gia_chot ===

-- Test 4a: Insert chi tiet cho mon MA1 (co khuyen mai KM1 giam 10000, han 2025-12-31)
-- MA1 gia goc = 45000, sau khuyen mai => Gia_chot mong doi = 35000
-- INSERT INTO CHI_TIET_DON_HANG (ID_don_hang, Ghi_chu, So_luong, ID_mon_an, Gia_chot)
-- VALUES (7, N'Test gia chot', 1, 1, 99999); -- Gia_chot 99999 se bi ghi de boi trigger
-- SELECT Gia_chot FROM CHI_TIET_DON_HANG WHERE ID_don_hang = 7 AND ID_mon_an = 1;
-- => Mong doi: 35000 (trigger tu dong ghi de thanh Gia goc - KhuyenMai)

-- Test 4b: Insert chi tiet cho mon khong co khuyen mai (MA3 - Pho ga, gia 40000)
-- INSERT INTO CHI_TIET_DON_HANG (ID_don_hang, So_luong, ID_mon_an, Gia_chot)
-- VALUES (7, 1, 3, 99999);
-- SELECT Gia_chot FROM CHI_TIET_DON_HANG WHERE ID_don_hang = 7 AND ID_mon_an = 3;
-- => Mong doi: 40000 (bang gia goc vi khong co khuyen mai)

-- === TEST 4.5 - Trigger dong bo trang thai don hang ===

-- Test 5a: Cap nhat trang thai TAI_XE_NHAN_DON -> kiem tra DON_HANG dong bo
-- UPDATE TAI_XE_NHAN_DON SET Trang_thai_don = N'Da_giao' WHERE ID_don_hang = 4;
-- SELECT Trang_thai FROM DON_HANG WHERE ID = 4;
-- => Mong doi: 'Da_giao' (duoc dong bo tu trigger)

-- Test 5b: Kiem tra Doanh_thu NH5 tang sau khi DH4 chuyen sang Da_giao
-- SELECT Doanh_thu FROM NHA_HANG WHERE ID_nha_hang = 5;
-- => Mong doi: 250000 (DH4 Lau thai hai san)

PRINT N'=== TAO 5 TRIGGERS THANH CONG ===';
GO
