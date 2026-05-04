-- =============================================
-- BTL2 - File 6: Functions
-- Cac ham su dung IF, LOOP, Cursor, Truy van, Kiem tra tham so dau vao.
-- =============================================
USE LogisticGiaoDoAn;
GO

-- =============================================
-- 6.1 FUNCTION TÍNH DOANH THU NHÀ HÀNG
-- Dùng con trỏ duyệt qua danh sách các đơn hàng hoàn thành để tính tổng.
-- =============================================
IF OBJECT_ID('fn_TinhDoanhThu', 'FN') IS NOT NULL DROP FUNCTION fn_TinhDoanhThu;
GO

CREATE FUNCTION fn_TinhDoanhThu
(
    @ID_nha_hang INT,
    @TuNgay DATETIME,
    @DenNgay DATETIME
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    -- 1. Kiem tra tham so dau vao
    IF @TuNgay > @DenNgay
    BEGIN
        RETURN -1; -- Loi: Ngay bat dau lon hon ngay ket thuc
    END

    IF NOT EXISTS (SELECT 1 FROM NHA_HANG WHERE ID_nha_hang = @ID_nha_hang)
    BEGIN
        RETURN -2; -- Loi: Nha hang khong ton tai
    END

    -- 2. Tinh toan su dung cursor
    DECLARE @TongDoanhThu DECIMAL(18,2) = 0;
    DECLARE @TienDonHang DECIMAL(18,2);

    -- Khai bao con tro truy van du lieu don hang
    DECLARE cur_DonHang CURSOR FOR
    SELECT Tong_tien
    FROM DON_HANG
    WHERE ID_nha_hang = @ID_nha_hang 
      AND Trang_thai = N'Da_giao'
      AND Thoi_gian BETWEEN @TuNgay AND @DenNgay;

    OPEN cur_DonHang;

    FETCH NEXT FROM cur_DonHang INTO @TienDonHang;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @TongDoanhThu = @TongDoanhThu + @TienDonHang;
        FETCH NEXT FROM cur_DonHang INTO @TienDonHang;
    END

    CLOSE cur_DonHang;
    DEALLOCATE cur_DonHang;

    RETURN @TongDoanhThu;
END
GO

-- =============================================
-- 6.2 FUNCTION XẾP HẠNG KHÁCH HÀNG DỰA VÀO TỔNG CHI TIÊU
-- Dùng con trỏ duyệt qua tổng chi tiêu của tất cả khách hàng, 
-- dùng IF/LOOP để tìm xếp hạng của một khách hàng cụ thể.
-- =============================================
IF OBJECT_ID('fn_XepHangKhachHang', 'FN') IS NOT NULL DROP FUNCTION fn_XepHangKhachHang;
GO

CREATE FUNCTION fn_XepHangKhachHang
(
    @ID_khach_hang INT
)
RETURNS INT
AS
BEGIN
    -- 1. Kiem tra tham so dau vao
    IF NOT EXISTS (SELECT 1 FROM KHACH_HANG WHERE ID = @ID_khach_hang)
    BEGIN
        RETURN -1; -- Khach hang khong ton tai
    END

    -- 2. Khai bao bien
    DECLARE @TongChiTieu DECIMAL(18,2);
    DECLARE @KhachHangHienTai INT;
    DECLARE @ThuHang INT = 1;
    DECLARE @MucChiTieu_KhachHangCanTim DECIMAL(18,2) = 0;

    -- Lay tong chi tieu cua khach hang can tim
    SELECT @MucChiTieu_KhachHangCanTim = ISNULL(SUM(Tong_tien), 0)
    FROM DON_HANG
    WHERE ID_khach_hang = @ID_khach_hang AND Trang_thai = N'Da_giao';

    -- Su dung cursor duyet tat ca tong chi tieu tu cao xuong thap
    DECLARE cur_ChiTieu CURSOR FOR
    SELECT kh.ID, ISNULL(SUM(dh.Tong_tien), 0) AS TongChi
    FROM KHACH_HANG kh
    LEFT JOIN DON_HANG dh ON kh.ID = dh.ID_khach_hang AND dh.Trang_thai = N'Da_giao'
    GROUP BY kh.ID
    ORDER BY TongChi DESC;

    OPEN cur_ChiTieu;
    FETCH NEXT FROM cur_ChiTieu INTO @KhachHangHienTai, @TongChiTieu;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Dung loop: Neu chi tieu cua KH hien thi trong cursor > chi tieu cua KH can tim, hang bi thut 1
        IF @TongChiTieu > @MucChiTieu_KhachHangCanTim
        BEGIN
            SET @ThuHang = @ThuHang + 1;
        END
        ELSE
        BEGIN
            -- Vi cursor sap xep giam dan, neu gap muc chi tieu <= muc can tim thi do chinh la thu hang
            -- (Dung Break bang cach de dieu kien while sai di - do TSQL FUNCTION khong ho tro BREAK)
            -- Trong TSQL, co the chi can thot khoi vong lap bang return.
            -- RETURN @ThuHang;
            -- Hay nhat la kiem tra dung ID
            IF @KhachHangHienTai = @ID_khach_hang
            BEGIN
                -- Thay thay the lenh BREAK bang SET FETCH_STATUS de an toan trong function. 
                -- Thuc te, Function UDF co ho tro BREAK.
                BREAK;
            END
        END

        FETCH NEXT FROM cur_ChiTieu INTO @KhachHangHienTai, @TongChiTieu;
    END

    CLOSE cur_ChiTieu;
    DEALLOCATE cur_ChiTieu;

    RETURN @ThuHang;
END
GO

-- =============================================
-- TEST CASES minh hoa
-- =============================================
-- 1. Test function TinhDoanhThu:
-- SELECT dbo.fn_TinhDoanhThu(1, '2025-09-01', '2025-09-30') AS DoanhThuNhaHang1;
-- 2. Test function XepHangKhachHang:
-- SELECT dbo.fn_XepHangKhachHang(1) AS HangCuaKhachHang1;
-- SELECT tk.Ten, dbo.fn_XepHangKhachHang(kh.ID) AS XepHang
-- FROM KHACH_HANG kh JOIN TAI_KHOAN_NGUOI_DUNG tk ON kh.ID = tk.ID;

PRINT N'=== TAO FUNCTION THANH CONG ===';
GO
