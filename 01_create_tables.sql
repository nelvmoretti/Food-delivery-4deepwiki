-- =============================================
-- BTL2 - HE CO SO DU LIEU - HK252
-- Nhom 4 - Lop L04
-- Chu de: Logistic Giao Do An
-- File 1: Tao tat ca bang du lieu 
-- =============================================

USE master;
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'LogisticGiaoDoAn')
    CREATE DATABASE LogisticGiaoDoAn;
GO

USE LogisticGiaoDoAn;
GO

-- =============================================
-- Xoa bang theo thu tu nguoc dependency
-- =============================================
IF OBJECT_ID('TAI_XE_NHAN_DON', 'U') IS NOT NULL DROP TABLE TAI_XE_NHAN_DON;
IF OBJECT_ID('DANH_GIA', 'U') IS NOT NULL DROP TABLE DANH_GIA;
IF OBJECT_ID('CHI_TIET_DON_HANG', 'U') IS NOT NULL DROP TABLE CHI_TIET_DON_HANG;
IF OBJECT_ID('DON_HANG', 'U') IS NOT NULL DROP TABLE DON_HANG;
IF OBJECT_ID('MON_AN_TRONG_GIO_HANG', 'U') IS NOT NULL DROP TABLE MON_AN_TRONG_GIO_HANG;
IF OBJECT_ID('GIO_HANG', 'U') IS NOT NULL DROP TABLE GIO_HANG;
IF OBJECT_ID('KHUYEN_MAI_CHO_MON_AN', 'U') IS NOT NULL DROP TABLE KHUYEN_MAI_CHO_MON_AN;
IF OBJECT_ID('MON_AN', 'U') IS NOT NULL DROP TABLE MON_AN;
IF OBJECT_ID('GIAM_SAT', 'U') IS NOT NULL DROP TABLE GIAM_SAT;
IF OBJECT_ID('SO_DIEN_THOAI', 'U') IS NOT NULL DROP TABLE SO_DIEN_THOAI;
IF OBJECT_ID('TAI_XE', 'U') IS NOT NULL DROP TABLE TAI_XE;
IF OBJECT_ID('NHAN_VIEN', 'U') IS NOT NULL DROP TABLE NHAN_VIEN;
IF OBJECT_ID('KHACH_HANG', 'U') IS NOT NULL DROP TABLE KHACH_HANG;
IF OBJECT_ID('TAI_KHOAN_NGUOI_DUNG', 'U') IS NOT NULL DROP TABLE TAI_KHOAN_NGUOI_DUNG;
IF OBJECT_ID('THANH_TOAN', 'U') IS NOT NULL DROP TABLE THANH_TOAN;
IF OBJECT_ID('KHUYEN_MAI', 'U') IS NOT NULL DROP TABLE KHUYEN_MAI;
IF OBJECT_ID('NHA_HANG', 'U') IS NOT NULL DROP TABLE NHA_HANG;
GO

-- =============================================
-- 1. NHA_HANG
-- =============================================
CREATE TABLE NHA_HANG (
    ID_nha_hang INT IDENTITY(1,1) PRIMARY KEY,
    Ten NVARCHAR(100) NOT NULL,
    Dia_chi NVARCHAR(255) NOT NULL,
    Thoi_gian_hoat_dong NVARCHAR(100),
    Doanh_thu DECIMAL(18,2) DEFAULT 0 -- Thuoc tinh dan xuat
    -- Doanh_thu: derived attribute (có thể tính từ DON_HANG)
    -- Tong_tien: derived attribute (tính từ CHI_TIET_DON_HANG)
);
GO

-- =============================================
-- 2. KHUYEN_MAI
-- =============================================
CREATE TABLE KHUYEN_MAI (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    Tien_giam_gia DECIMAL(18,2) NOT NULL,
    Han_su_dung DATETIME NOT NULL,
    CONSTRAINT CK_KM_TienGiam CHECK (Tien_giam_gia >= 0)
);
GO

-- =============================================
-- 3. THANH_TOAN
-- =============================================
CREATE TABLE THANH_TOAN (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    Phuong_thuc NVARCHAR(50) NOT NULL,
    Trang_thai NVARCHAR(50) NOT NULL DEFAULT N'Cho_thanh_toan',
    Thoi_gian_thanh_toan DATETIME,
    CONSTRAINT CK_TT_PhuongThuc CHECK (Phuong_thuc IN (N'Tien_mat', N'The_tin_dung', N'Vi_dien_tu', N'Chuyen_khoan')),
    CONSTRAINT CK_TT_TrangThai CHECK (Trang_thai IN (N'Cho_thanh_toan', N'Da_thanh_toan', N'Hoan_tien', N'Da_huy'))
);
GO

-- =============================================
-- 4. TAI_KHOAN_NGUOI_DUNG
-- =============================================
CREATE TABLE TAI_KHOAN_NGUOI_DUNG (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    Ho NVARCHAR(50) NOT NULL,
    Ten_lot NVARCHAR(50),
    Ten NVARCHAR(50) NOT NULL,
    Mat_khau NVARCHAR(255) NOT NULL,
    email NVARCHAR(100) NOT NULL,
    Phan_loai_nguoi_dung NVARCHAR(20) NOT NULL,
    CONSTRAINT CK_TKND_Email CHECK (email LIKE '%_@_%._%'),
    CONSTRAINT CK_TKND_PhanLoai CHECK (Phan_loai_nguoi_dung IN (N'Khach_hang', N'Nhan_vien', N'Tai_xe')),
    CONSTRAINT UQ_TKND_Email UNIQUE (email)
);
GO

-- =============================================
-- 5. KHACH_HANG
-- =============================================
CREATE TABLE KHACH_HANG (
    ID INT PRIMARY KEY,
    Dia_chi NVARCHAR(255),
    Nghe_nghiep NVARCHAR(100),
    CONSTRAINT FK_KH_TKND FOREIGN KEY (ID) REFERENCES TAI_KHOAN_NGUOI_DUNG(ID)
);
GO

-- =============================================
-- 6. NHAN_VIEN
-- =============================================
CREATE TABLE NHAN_VIEN (
    ID INT PRIMARY KEY,
    Vai_tro NVARCHAR(100) NOT NULL,
    Cap_do_quyen INT NOT NULL DEFAULT 1,
    CONSTRAINT FK_NV_TKND FOREIGN KEY (ID) REFERENCES TAI_KHOAN_NGUOI_DUNG(ID),
    CONSTRAINT CK_NV_CapDoQuyen CHECK (Cap_do_quyen >= 1)
);
GO

-- =============================================
-- 7. TAI_XE
-- =============================================
CREATE TABLE TAI_XE (
    ID INT PRIMARY KEY,
    Phuong_tien NVARCHAR(100) NOT NULL,
    Trang_thai NVARCHAR(50) NOT NULL DEFAULT N'Offline',
    Bang_lai NVARCHAR(50) NOT NULL,
    CONSTRAINT FK_TX_TKND FOREIGN KEY (ID) REFERENCES TAI_KHOAN_NGUOI_DUNG(ID),
    CONSTRAINT CK_TX_TrangThai CHECK (Trang_thai IN (N'Online', N'Offline', N'Dang_giao'))
);
GO

-- =============================================
-- 8. SO_DIEN_THOAI
-- =============================================
CREATE TABLE SO_DIEN_THOAI (
    SDT_chinh VARCHAR(15) NOT NULL,
    id_nguoi_dung INT NOT NULL,
    CONSTRAINT PK_SDT PRIMARY KEY (SDT_chinh, id_nguoi_dung),
    CONSTRAINT FK_SDT_TKND FOREIGN KEY (id_nguoi_dung) REFERENCES TAI_KHOAN_NGUOI_DUNG(ID),
    CONSTRAINT CK_SDT_Format CHECK (SDT_chinh LIKE '0[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]%')
);
GO

-- =============================================
-- 9. GIAM_SAT (Moi nhan vien co toi da 1 quan ly)
-- =============================================
CREATE TABLE GIAM_SAT (
    Nguoi_bi_quan_ly_ID INT PRIMARY KEY,
    Nguoi_quan_ly_ID INT NOT NULL,
    CONSTRAINT FK_GS_NguoiBiQL FOREIGN KEY (Nguoi_bi_quan_ly_ID) REFERENCES NHAN_VIEN(ID),
    CONSTRAINT FK_GS_NguoiQL FOREIGN KEY (Nguoi_quan_ly_ID) REFERENCES NHAN_VIEN(ID),
    CONSTRAINT CK_GS_KhongTuQuanLy CHECK (Nguoi_bi_quan_ly_ID <> Nguoi_quan_ly_ID)
);
GO

-- =============================================
-- 10. MON_AN
-- ** THAY DOI: ID_nguoi_duyet INT -> NOT NULL **
-- Muc 4.5: Mon an bat buoc phai co nhan vien duyet
-- =============================================
CREATE TABLE MON_AN (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    ID_nha_hang INT NOT NULL,
    Ten NVARCHAR(200) NOT NULL,
    Gia DECIMAL(18,2) NOT NULL,
    ID_nguoi_duyet INT NOT NULL,
    CONSTRAINT FK_MA_NhaHang FOREIGN KEY (ID_nha_hang) REFERENCES NHA_HANG(ID_nha_hang),
    CONSTRAINT FK_MA_NguoiDuyet FOREIGN KEY (ID_nguoi_duyet) REFERENCES NHAN_VIEN(ID),
    CONSTRAINT CK_MA_Gia CHECK (Gia > 0)
);
GO

-- =============================================
-- 11. KHUYEN_MAI_CHO_MON_AN
-- =============================================
CREATE TABLE KHUYEN_MAI_CHO_MON_AN (
    ID_mon_an INT NOT NULL,
    ID_khuyen_mai INT NOT NULL,
    Dieu_kien NVARCHAR(255),
    CONSTRAINT PK_KMCMA PRIMARY KEY (ID_mon_an, ID_khuyen_mai),
    CONSTRAINT FK_KMCMA_MonAn FOREIGN KEY (ID_mon_an) REFERENCES MON_AN(ID),
    CONSTRAINT FK_KMCMA_KhuyenMai FOREIGN KEY (ID_khuyen_mai) REFERENCES KHUYEN_MAI(ID)
);
GO

-- =============================================
-- 12. GIO_HANG
-- ** THAY DOI: Them UNIQUE cho ID_khach_hang **
-- Muc 2: Dam bao quan he 1:1 giua Khach hang va Gio hang
-- =============================================
CREATE TABLE GIO_HANG (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    Thoi_gian_tao DATETIME NOT NULL DEFAULT GETDATE(),
    Trang_thai NVARCHAR(50) NOT NULL DEFAULT N'Dang_mo',
    ID_khach_hang INT NOT NULL UNIQUE,
    CONSTRAINT FK_GH_KhachHang FOREIGN KEY (ID_khach_hang) REFERENCES KHACH_HANG(ID),
    CONSTRAINT CK_GH_TrangThai CHECK (Trang_thai IN (N'Dang_mo', N'Da_dat_hang', N'Da_huy'))
);
GO

-- =============================================
-- 13. MON_AN_TRONG_GIO_HANG
-- =============================================
CREATE TABLE MON_AN_TRONG_GIO_HANG (
    ID_gio_hang INT NOT NULL,
    ID_mon_an INT NOT NULL,
    so_luong INT NOT NULL,
    Gia_tien DECIMAL(18,2) NOT NULL,
    CONSTRAINT PK_MATGH PRIMARY KEY (ID_gio_hang, ID_mon_an),
    CONSTRAINT FK_MATGH_GioHang FOREIGN KEY (ID_gio_hang) REFERENCES GIO_HANG(ID),
    CONSTRAINT FK_MATGH_MonAn FOREIGN KEY (ID_mon_an) REFERENCES MON_AN(ID),
    CONSTRAINT CK_MATGH_SoLuong CHECK (so_luong > 0),
    CONSTRAINT CK_MATGH_GiaTien CHECK (Gia_tien > 0)
);
GO

-- =============================================
-- 14. DON_HANG
-- ** THAY DOI: **
-- Muc 1: ID_thanh_toan INT NOT NULL UNIQUE (1:1 Mandatory)
-- Muc 4.6: ID_khach_hang INT NULL (cho phep khach vang lai)
-- =============================================
CREATE TABLE DON_HANG (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    Thoi_gian DATETIME NOT NULL DEFAULT GETDATE(),
    Trang_thai NVARCHAR(50) NOT NULL DEFAULT N'Cho_xac_nhan',
    ID_thanh_toan INT NOT NULL UNIQUE,
    Tong_tien DECIMAL(18,2) DEFAULT 0,
    ID_nha_hang INT NOT NULL,
    ID_khach_hang INT NOT NULL, 
    ID_nhan_vien INT NULL, -- Nhan vien xu ly don, NULL vi Don hang optional
    CONSTRAINT FK_DH_ThanhToan FOREIGN KEY (ID_thanh_toan) REFERENCES THANH_TOAN(ID),
    CONSTRAINT FK_DH_NhaHang FOREIGN KEY (ID_nha_hang) REFERENCES NHA_HANG(ID_nha_hang),
    CONSTRAINT FK_DH_KhachHang FOREIGN KEY (ID_khach_hang) REFERENCES KHACH_HANG(ID),
    CONSTRAINT FK_DH_NhanVien FOREIGN KEY (ID_nhan_vien) REFERENCES NHAN_VIEN(ID),
    CONSTRAINT CK_DH_TongTien CHECK (Tong_tien >= 0),
    CONSTRAINT CK_DH_TrangThai CHECK (Trang_thai IN (N'Cho_xac_nhan', N'Da_xac_nhan', N'Dang_chuan_bi', N'Dang_giao', N'Da_giao', N'Da_huy'))
);
GO

-- =============================================
-- 15. CHI_TIET_DON_HANG
-- =============================================
CREATE TABLE CHI_TIET_DON_HANG (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    ID_don_hang INT NOT NULL,
    Ghi_chu NVARCHAR(500),
    So_luong INT NOT NULL,
    ID_mon_an INT NOT NULL,
    Gia_chot DECIMAL(18,2) NOT NULL,
    CONSTRAINT FK_CTDH_DonHang FOREIGN KEY (ID_don_hang) REFERENCES DON_HANG(ID),
    CONSTRAINT FK_CTDH_MonAn FOREIGN KEY (ID_mon_an) REFERENCES MON_AN(ID),
    CONSTRAINT CK_CTDH_SoLuong CHECK (So_luong > 0),
    CONSTRAINT CK_CTDH_GiaChot CHECK (Gia_chot > 0)
);
GO

-- =============================================
-- 16. DANH_GIA
-- =============================================
CREATE TABLE DANH_GIA (
    ID_khach_hang INT NOT NULL,
    ID_mon_an INT NOT NULL,
    Thoi_gian DATETIME NOT NULL DEFAULT GETDATE(),
    Binh_luan NVARCHAR(1000),
    Xep_hang INT NOT NULL,
    CONSTRAINT PK_DG PRIMARY KEY (ID_khach_hang, ID_mon_an, Thoi_gian),
    CONSTRAINT FK_DG_KhachHang FOREIGN KEY (ID_khach_hang) REFERENCES KHACH_HANG(ID),
    CONSTRAINT FK_DG_MonAn FOREIGN KEY (ID_mon_an) REFERENCES MON_AN(ID),
    CONSTRAINT CK_DG_XepHang CHECK (Xep_hang BETWEEN 1 AND 5)
);
GO

-- =============================================
-- 17. TAI_XE_NHAN_DON
-- ** Muc 4.4: ID_don_hang la PRIMARY KEY (N:1, 1 don chi 1 tai xe) **
-- =============================================
CREATE TABLE TAI_XE_NHAN_DON (
    ID_don_hang INT NOT NULL PRIMARY KEY,
    ID_tai_xe INT NOT NULL ,
    Trang_thai_don NVARCHAR(50) NOT NULL DEFAULT N'Da_nhan',
    Thoi_gian_nhan_don DATETIME NOT NULL DEFAULT GETDATE(),
    Thoi_gian_tra_don DATETIME,
    CONSTRAINT FK_TXND_DonHang FOREIGN KEY (ID_don_hang) REFERENCES DON_HANG(ID),
    CONSTRAINT FK_TXND_TaiXe FOREIGN KEY (ID_tai_xe) REFERENCES TAI_XE(ID),
    CONSTRAINT CK_TXND_TrangThai CHECK (Trang_thai_don IN (N'Da_nhan', N'Dang_giao', N'Da_giao', N'Da_huy'))
);
GO

PRINT N'=== TAO 17 BANG THANH CONG ===';
GO
