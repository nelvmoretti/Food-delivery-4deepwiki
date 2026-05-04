-- =============================================
-- BTL2 - File 4: Triggers
-- 1. Trigger rang buoc nghiep vu
-- 2. Trigger tinh thuoc tinh dan xuat
-- =============================================
USE LogisticGiaoDoAn;
GO

-- =============================================
-- 4.1. TRIGGER RANG BUOC NGHIEP VU
-- Rang buoc: Mot tai xe chi duoc nhan don hang moi khi KHONG co don hang nao dang giao.
-- Thao tac DML bi anh huong: INSERT, UPDATE tren TAI_XE_NHAN_DON
-- =============================================
IF OBJECT_ID('trg_CheckTaiXeNhanDon', 'TR') IS NOT NULL DROP TRIGGER trg_CheckTaiXeNhanDon;
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
        AND t.ID_don_hang <> i.ID_don_hang -- Khong tinh chinh don hang dang duoc insert/update
    )
    BEGIN
        RAISERROR(N'Loi nghiep vu: Tai xe dang co don hang o trang thai Dang_giao, khong the nhan don moi.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- Cap nhat trang thai tai xe thanh Dang_giao hoac Online tuong ung neu don giao/hoan thanh
    UPDATE tx
    SET Trang_thai = CASE 
                        WHEN i.Trang_thai_don = N'Dang_giao' THEN N'Dang_giao'
                        WHEN i.Trang_thai_don IN (N'Da_giao', N'Da_huy') THEN N'Online'
                        ELSE tx.Trang_thai
                     END
    FROM TAI_XE tx
    JOIN inserted i ON tx.ID = i.ID_tai_xe;
END
GO


-- =============================================
-- 4.2. TRIGGER TINH THUOC TINH DAN XUAT
-- Thuoc tinh: Tong_tien cua DON_HANG va Doanh_thu cua NHA_HANG
-- =============================================
-- Luu y: Doanh_thu cua nha hang phu thuoc vao Tong_tien cua cac don hang Da_giao.
-- => Khi CHI_TIET_DON_HANG thay doi -> Cap nhat Tong_tien DON_HANG -> Cap nhat Doanh_thu NHA_HANG
-- =============================================

-- A. Trigger khi them/sua/xoa CHI TIET DON HANG -> Cap nhat Tong_tien cua DON_HANG
IF OBJECT_ID('trg_UpdateTongTienDonHang', 'TR') IS NOT NULL DROP TRIGGER trg_UpdateTongTienDonHang;
GO

CREATE TRIGGER trg_UpdateTongTienDonHang
ON CHI_TIET_DON_HANG
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @DonHangID INT;

    -- Lay ID don hang tu bang inserted hoac deleted
    IF EXISTS (SELECT 1 FROM inserted)
        SELECT TOP 1 @DonHangID = ID_don_hang FROM inserted;
    ELSE
        SELECT TOP 1 @DonHangID = ID_don_hang FROM deleted;

    -- Tinh tong tien moi tu CHI_TIET_DON_HANG
    -- Tong_tien = SUM(So_luong * Gia_chot)
    DECLARE @TongTien DECIMAL(18,2) = 0;
    SELECT @TongTien = ISNULL(SUM(So_luong * Gia_chot), 0)
    FROM CHI_TIET_DON_HANG
    WHERE ID_don_hang = @DonHangID;

    -- Cap nhat Tong_tien vao DON_HANG
    UPDATE DON_HANG
    SET Tong_tien = @TongTien
    WHERE ID = @DonHangID;
END
GO

-- B. Trigger khi cap nhat DON_HANG -> Cap nhat Doanh_thu cua NHA_HANG
IF OBJECT_ID('trg_UpdateDoanhThuNhaHang', 'TR') IS NOT NULL DROP TRIGGER trg_UpdateDoanhThuNhaHang;
GO

CREATE TRIGGER trg_UpdateDoanhThuNhaHang
ON DON_HANG
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NhaHangID INT;

    -- Xac dinh nha hang nao bi anh huong
    IF EXISTS (SELECT 1 FROM inserted)
        SELECT TOP 1 @NhaHangID = ID_nha_hang FROM inserted;
    ELSE
        SELECT TOP 1 @NhaHangID = ID_nha_hang FROM deleted;

    -- Tinh lai doanh thu (chi tinh don hoan thanh - 'Da_giao')
    DECLARE @DoanhThu DECIMAL(18,2) = 0;
    SELECT @DoanhThu = ISNULL(SUM(Tong_tien), 0)
    FROM DON_HANG
    WHERE ID_nha_hang = @NhaHangID AND Trang_thai = N'Da_giao';

    -- Cap nhat Doanh_thu cho NHA_HANG
    UPDATE NHA_HANG
    SET Doanh_thu = @DoanhThu
    WHERE ID_nha_hang = @NhaHangID;
END
GO

-- =============================================
-- TEST CASES minh hoa
-- =============================================

-- Test Trigger Nghiệp Vụ:
-- B1: INSERT don hang cho tai xe 11 dang ranh (thanh cong)
-- INSERT INTO TAI_XE_NHAN_DON (ID_don_hang, ID_tai_xe, Trang_thai_don) VALUES (5, 11, N'Da_nhan'); 
-- B2: UPDATE trang thai thanh Dang_giao cho don 5 (thanh cong)
-- UPDATE TAI_XE_NHAN_DON SET Trang_thai_don = N'Dang_giao' WHERE ID_don_hang = 5 AND ID_tai_xe = 11;
-- B3: INSERT don moi cho tai xe 11 trong khi don 5 van Dang_giao (Loi)
-- INSERT INTO TAI_XE_NHAN_DON (ID_don_hang, ID_tai_xe, Trang_thai_don) VALUES (6, 11, N'Da_nhan');

-- Test Trigger Dẫn Xuất:
-- B1: Xem doanh thu nha hang hien tai (vd NH 1)
-- SELECT ID_nha_hang, Ten, Doanh_thu FROM NHA_HANG WHERE ID_nha_hang = 1;
-- B2: Them 1 chi tiet don hang cho don hang thuoc NH 1
-- INSERT INTO CHI_TIET_DON_HANG (ID_don_hang, So_luong, ID_mon_an, Gia_chot) VALUES (1, 1, 1, 50000);
-- B3: Kiem tra lai tong tien DH 1 va doanh thu NH 1 (da duoc cap nhat tang 50k)
-- SELECT Tong_tien FROM DON_HANG WHERE ID = 1;
-- SELECT Doanh_thu FROM NHA_HANG WHERE ID_nha_hang = 1;

PRINT N'=== TAO TRIGGERS THANH CONG ===';
GO
