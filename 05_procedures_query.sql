-- =============================================
-- BTL2 - File 5: Procedures truy van
-- =============================================
USE LogisticGiaoDoAn;
GO

-- =============================================
-- 5.1 PROCEDURE TRUY VAN DON HANG (>= 2 BANG, WHERE, ORDER BY)
-- Hien thi lich su don hang theo khach hang trong khoang thoi gian.
-- Lien ket bang: DON_HANG, KHACH_HANG, TAI_KHOAN_NGUOI_DUNG, NHA_HANG
-- =============================================
IF OBJECT_ID('sp_LichSuDonHangCuaKhach', 'P') IS NOT NULL DROP PROCEDURE sp_LichSuDonHangCuaKhach;
GO

CREATE PROCEDURE sp_LichSuDonHangCuaKhach
    @ID_khach_hang INT,
    @TuNgay DATETIME,
    @DenNgay DATETIME
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        dh.ID AS MaDonHang,
        dh.Thoi_gian AS ThoiGianDat,
        dh.Trang_thai AS TrangThai,
        dh.Tong_tien AS TongTien,
        nh.Ten AS TenNhaHang,
        tk.Ho + ' ' + ISNULL(tk.Ten_lot + ' ', '') + tk.Ten AS TenKhachHang
    FROM DON_HANG dh
    JOIN KHACH_HANG kh ON dh.ID_khach_hang = kh.ID
    JOIN TAI_KHOAN_NGUOI_DUNG tk ON kh.ID = tk.ID
    JOIN NHA_HANG nh ON dh.ID_nha_hang = nh.ID_nha_hang
    WHERE dh.ID_khach_hang = @ID_khach_hang
      AND dh.Thoi_gian BETWEEN @TuNgay AND @DenNgay
    ORDER BY dh.Thoi_gian DESC;
END
GO

-- =============================================
-- 5.2 PROCEDURE THONG KE DOANH THU THEO NHA HANG 
-- (>= 2 BANG, GROUP BY, HAVING, WHERE, ORDER BY)
-- Thong ke nhung nha hang co tong doanh thu cac don hang hoan thanh trong khoang thoi gian vuot muc toi thieu.
-- =============================================
IF OBJECT_ID('sp_ThongKeNhaHangDoanhThuCao', 'P') IS NOT NULL DROP PROCEDURE sp_ThongKeNhaHangDoanhThuCao;
GO

CREATE PROCEDURE sp_ThongKeNhaHangDoanhThuCao
    @TuNgay DATETIME,
    @DenNgay DATETIME,
    @DoanhThuToiThieu DECIMAL(18,2)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        nh.ID_nha_hang AS MaNhaHang,
        nh.Ten AS TenNhaHang,
        COUNT(dh.ID) AS SoDonHoanThanh,
        SUM(dh.Tong_tien) AS TongDoanhThu
    FROM NHA_HANG nh
    JOIN DON_HANG dh ON nh.ID_nha_hang = dh.ID_nha_hang
    WHERE dh.Trang_thai = N'Da_giao'
      AND dh.Thoi_gian BETWEEN @TuNgay AND @DenNgay
    GROUP BY nh.ID_nha_hang, nh.Ten
    HAVING SUM(dh.Tong_tien) >= @DoanhThuToiThieu
    ORDER BY TongDoanhThu DESC;
END
GO

-- =============================================
-- TEST CASES minh hoa
-- =============================================

-- 1. Xem lich su don hang cua KH 1 tu 01/09 toi 30/09
-- EXEC sp_LichSuDonHangCuaKhach @ID_khach_hang = 1, @TuNgay = '2025-09-01', @DenNgay = '2025-09-30';

-- 2. Xem nha hang nao co doanh thu > 100k tu cac don hoan thanh tu 01/09 toi 30/09
-- EXEC sp_ThongKeNhaHangDoanhThuCao @TuNgay = '2025-09-01', @DenNgay = '2025-09-30', @DoanhThuToiThieu = 100000;

PRINT N'=== TAO PROCEDURE TRUY VAN THANH CONG ===';
GO
