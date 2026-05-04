-- =============================================
-- BTL2 - HE CO SO DU LIEU - HK252
-- Nhom 4 - Lop L04
-- Chu de: Logistic Giao Do An
-- File 2: Du lieu mau (>= 5 dong moi bang)
-- Nguoi thuc hien: Person 2
-- =============================================
USE LogisticGiaoDoAn;
GO

-- =============================================
-- 1. NHA_HANG (5 nha hang Viet Nam thuc te)
-- =============================================
INSERT INTO NHA_HANG (Ten, Dia_chi, Thoi_gian_hoat_dong, Doanh_thu) VALUES
(N'Pho Thin', N'13 Lo Duc, Hai Ba Trung, Ha Noi', N'06:00 - 21:00', 0),
(N'Bun Cha Huong Lien', N'24 Le Van Huu, Hai Ba Trung, Ha Noi', N'09:00 - 20:00', 0),
(N'Com Tam Sai Gon', N'15 Nguyen Trai, Quan 1, TP.HCM', N'06:00 - 22:00', 0),
(N'Banh Mi Huynh Hoa', N'26 Le Thi Rieng, Quan 1, TP.HCM', N'14:30 - 23:00', 0),
(N'Lau Hai San Bien Dong', N'88 Tran Hung Dao, Quan 5, TP.HCM', N'10:00 - 23:00', 0);
-- Doanh_thu = 0 vi la thuoc tinh dan xuat, se duoc trigger (P3) cap nhat sau
GO

-- =============================================
-- 2. KHUYEN_MAI (5 chuong trinh khuyen mai)
-- =============================================
INSERT INTO KHUYEN_MAI (Tien_giam_gia, Han_su_dung) VALUES
(10000, '2025-12-31'),
(20000, '2025-11-30'),
(15000, '2025-10-31'),
(50000, '2025-12-15'),
(5000, '2026-01-31');
GO

-- =============================================
-- 3. THANH_TOAN
-- Luu y: DON_HANG.ID_thanh_toan la NOT NULL UNIQUE (1 don = 1 thanh toan rieng)
-- Bao gom du 4 trang thai: Da_thanh_toan, Cho_thanh_toan, Hoan_tien, Da_huy
-- =============================================
INSERT INTO THANH_TOAN (Phuong_thuc, Trang_thai, Thoi_gian_thanh_toan) VALUES
(N'Tien_mat', N'Da_thanh_toan', '2025-09-01 12:30:00'),       -- TT1 -> DH1 (Da_giao)
(N'Vi_dien_tu', N'Da_thanh_toan', '2025-09-01 13:00:00'),     -- TT2 -> DH2 (Da_giao)
(N'The_tin_dung', N'Da_thanh_toan', '2025-09-02 11:00:00'),   -- TT3 -> DH3 (Da_giao)
(N'Chuyen_khoan', N'Cho_thanh_toan', NULL),                    -- TT4 -> DH4 (Dang_giao)
(N'Tien_mat', N'Da_thanh_toan', '2025-09-03 19:00:00'),       -- TT5 -> DH5 (Da_giao)
(N'Vi_dien_tu', N'Da_thanh_toan', '2025-09-04 12:00:00'),     -- TT6 -> DH6 (Da_giao)
(N'The_tin_dung', N'Cho_thanh_toan', NULL),                    -- TT7 -> DH7 (Cho_xac_nhan)
(N'Chuyen_khoan', N'Da_huy', NULL),                            -- TT8 -> DH8 (Da_huy)
(N'Vi_dien_tu', N'Hoan_tien', '2025-09-06 10:00:00');         -- TT9 -> DH9 (Da_huy, da hoan tien)
GO

-- =============================================
-- 4. TAI_KHOAN_NGUOI_DUNG (5 KH + 5 NV + 5 TX = 15)
-- =============================================
INSERT INTO TAI_KHOAN_NGUOI_DUNG (Ho, Ten_lot, Ten, Mat_khau, email, Phan_loai_nguoi_dung) VALUES
-- Khach hang (ID 1-5)
(N'Nguyen', N'Van', N'An', N'pass123', N'an.nguyen@gmail.com', N'Khach_hang'),
(N'Tran', N'Thi', N'Binh', N'pass123', N'binh.tran@gmail.com', N'Khach_hang'),
(N'Le', N'Hoang', N'Cuong', N'pass123', N'cuong.le@gmail.com', N'Khach_hang'),
(N'Pham', N'Minh', N'Duc', N'pass123', N'duc.pham@gmail.com', N'Khach_hang'),
(N'Vo', N'Thanh', N'Em', N'pass123', N'em.vo@gmail.com', N'Khach_hang'),
-- Nhan vien (ID 6-10)
(N'Hoang', N'Duc', N'Phuc', N'pass456', N'phuc.hoang@company.com', N'Nhan_vien'),
(N'Dang', N'Thi', N'Giang', N'pass456', N'giang.dang@company.com', N'Nhan_vien'),
(N'Bui', N'Van', N'Hai', N'pass456', N'hai.bui@company.com', N'Nhan_vien'),
(N'Do', N'Minh', N'Khoa', N'pass456', N'khoa.do@company.com', N'Nhan_vien'),
(N'Ngo', N'Thanh', N'Lam', N'pass456', N'lam.ngo@company.com', N'Nhan_vien'),
-- Tai xe (ID 11-15)
(N'Ly', N'Van', N'Manh', N'pass789', N'manh.ly@driver.com', N'Tai_xe'),
(N'Truong', N'Hoang', N'Nam', N'pass789', N'nam.truong@driver.com', N'Tai_xe'),
(N'Dinh', N'Duc', N'Phong', N'pass789', N'phong.dinh@driver.com', N'Tai_xe'),
(N'Luong', N'Van', N'Quang', N'pass789', N'quang.luong@driver.com', N'Tai_xe'),
(N'Mai', N'Thanh', N'Son', N'pass789', N'son.mai@driver.com', N'Tai_xe');
GO

-- =============================================
-- 5. KHACH_HANG (ID 1-5)
-- =============================================
INSERT INTO KHACH_HANG (ID, Dia_chi, Nghe_nghiep) VALUES
(1, N'12 Phan Chu Trinh, Ha Noi', N'Ky su'),
(2, N'45 Nguyen Hue, TP.HCM', N'Giao vien'),
(3, N'78 Le Loi, Da Nang', N'Sinh vien'),
(4, N'23 Tran Phu, Can Tho', N'Bac si'),
(5, N'56 Hai Ba Trung, Hue', N'Ke toan');
GO

-- =============================================
-- 6. NHAN_VIEN (ID 6-10)
-- =============================================
INSERT INTO NHAN_VIEN (ID, Vai_tro, Cap_do_quyen) VALUES
(6, N'Quan ly', 3),
(7, N'Duyet noi dung', 2),
(8, N'Ho tro khach hang', 1),
(9, N'Quan ly don hang', 2),
(10, N'Duyet noi dung', 2);
GO

-- =============================================
-- 7. TAI_XE (ID 11-15)
-- =============================================
INSERT INTO TAI_XE (ID, Phuong_tien, Trang_thai, Bang_lai) VALUES
(11, N'Honda Wave', N'Online', N'B2-001234'),
(12, N'Yamaha Exciter', N'Online', N'B2-005678'),
(13, N'Honda Vision', N'Offline', N'B2-009012'),
(14, N'Yamaha Sirius', N'Online', N'B2-003456'),
(15, N'Honda Air Blade', N'Offline', N'B2-007890');
GO

-- =============================================
-- 8. SO_DIEN_THOAI
-- Thuoc tinh da tri: 1 nguoi dung co the co nhieu SDT
-- KH An (ID=1) co 2 SDT de minh hoa thuoc tinh da tri
-- =============================================
INSERT INTO SO_DIEN_THOAI (SDT_chinh, id_nguoi_dung) VALUES
('0901234567', 1), ('0901234568', 1),  -- KH An co 2 SDT (da tri)
('0912345678', 2),
('0923456789', 3),
('0934567890', 4),
('0945678901', 5),
('0956789012', 6),
('0967890123', 7),
('0978901234', 8),
('0989012345', 9),
('0990123456', 10),
('0911111111', 11),
('0922222222', 12),
('0933333333', 13),
('0944444444', 14),
('0955555555', 15);  -- TX Son - bo sung (truoc day thieu)
GO

-- =============================================
-- 9. GIAM_SAT (NV6 quan ly NV7, NV8, NV9, NV10)
-- =============================================
INSERT INTO GIAM_SAT (Nguoi_bi_quan_ly_ID, Nguoi_quan_ly_ID) VALUES
(7, 6),
(8, 6),
(9, 6),
(10, 6);
GO

-- =============================================
-- 10. MON_AN (12 mon an tu 5 nha hang)
-- ID_nguoi_duyet la NOT NULL (bat buoc phai co NV duyet)
-- =============================================
INSERT INTO MON_AN (ID_nha_hang, Ten, Gia, ID_nguoi_duyet) VALUES
(1, N'Pho bo tai', 45000, 7),            -- MA1
(1, N'Pho bo chin', 45000, 7),           -- MA2
(1, N'Pho ga', 40000, 10),               -- MA3
(2, N'Bun cha Ha Noi', 50000, 7),        -- MA4
(2, N'Nem ran', 30000, 10),              -- MA5
(3, N'Com tam suon bi cha', 55000, 7),   -- MA6
(3, N'Com tam suon nuong', 45000, 10),   -- MA7
(4, N'Banh mi dac biet', 45000, 7),      -- MA8
(4, N'Banh mi thit nguoi', 35000, 10),   -- MA9
(5, N'Lau thai hai san', 250000, 7),     -- MA10
(5, N'Lau kim chi', 220000, 10),         -- MA11
(5, N'Tom nuong muoi ot', 150000, 7);    -- MA12
GO

-- =============================================
-- 11. KHUYEN_MAI_CHO_MON_AN (5 cap)
-- =============================================
INSERT INTO KHUYEN_MAI_CHO_MON_AN (ID_mon_an, ID_khuyen_mai, Dieu_kien) VALUES
(1, 1, N'Don hang tren 100.000d'),
(4, 2, N'Khach hang moi'),
(6, 3, N'Dat tu 2 phan tro len'),
(10, 4, N'Don hang tren 500.000d'),
(8, 5, N'Gio vang 11h-13h');
GO

-- =============================================
-- 12. GIO_HANG
-- ID_khach_hang UNIQUE (quan he 1:1 KH - Gio hang)
-- =============================================
INSERT INTO GIO_HANG (Thoi_gian_tao, Trang_thai, ID_khach_hang) VALUES
('2025-09-01 11:00:00', N'Da_dat_hang', 1),
('2025-09-01 12:00:00', N'Da_dat_hang', 2),
('2025-09-02 10:00:00', N'Da_dat_hang', 3),
('2025-09-03 18:00:00', N'Da_dat_hang', 4),
('2025-09-04 11:30:00', N'Dang_mo', 5);
GO

-- =============================================
-- 13. MON_AN_TRONG_GIO_HANG
-- =============================================
INSERT INTO MON_AN_TRONG_GIO_HANG (ID_gio_hang, ID_mon_an, so_luong, Gia_tien) VALUES
(1, 1, 2, 45000),
(1, 3, 1, 40000),
(2, 4, 1, 50000),
(2, 5, 2, 30000),
(3, 6, 1, 55000),
(3, 7, 1, 45000),
(4, 10, 1, 250000),
(5, 8, 1, 45000);
GO

-- =============================================
-- 14. DON_HANG
-- ID_thanh_toan: NOT NULL UNIQUE (1:1 voi THANH_TOAN)
-- Tong_tien: tinh thu cong = SUM(So_luong * Gia_chot) tu CHI_TIET
--   (Trigger P3 se tu dong tinh khi co thay doi sau nay)
-- Du cac trang thai: Da_giao, Dang_giao, Cho_xac_nhan, Da_huy
-- =============================================
INSERT INTO DON_HANG (Thoi_gian, Trang_thai, ID_thanh_toan, Tong_tien, ID_nha_hang, ID_khach_hang, ID_nhan_vien) VALUES
('2025-09-01 12:15:00', N'Da_giao',       1, 130000, 1, 1, 9),   -- DH1: 2*45k + 1*40k
('2025-09-01 12:45:00', N'Da_giao',       2, 110000, 2, 2, 9),   -- DH2: 1*50k + 2*30k
('2025-09-02 10:30:00', N'Da_giao',       3, 100000, 3, 3, 8),   -- DH3: 1*55k + 1*45k
('2025-09-03 18:30:00', N'Dang_giao',     4, 250000, 5, 4, NULL), -- DH4: 1*250k
('2025-09-04 11:45:00', N'Da_giao',       5, 175000, 1, 5, 9),   -- DH5: 2*45k + 1*45k + 1*40k
('2025-09-04 12:15:00', N'Da_giao',       6,  55000, 3, 1, 8),   -- DH6: 1*55k
('2025-09-05 10:00:00', N'Cho_xac_nhan',  7,  45000, 4, 2, NULL), -- DH7: 1*45k (chua xac nhan)
('2025-09-05 14:00:00', N'Da_huy',        8,  30000, 2, 3, 9),   -- DH8: 1*30k (da huy)
('2025-09-06 09:00:00', N'Da_huy',        9,  45000, 1, 4, 8);   -- DH9: 1*45k (da huy, da hoan tien)
GO

-- =============================================
-- 15. CHI_TIET_DON_HANG
-- Moi don hang phai co it nhat 1 chi tiet (rang buoc ngu nghia)
-- Gia_chot = gia mon an tai thoi diem dat, khong doi sau nay
-- =============================================
INSERT INTO CHI_TIET_DON_HANG (ID_don_hang, Ghi_chu, So_luong, ID_mon_an, Gia_chot) VALUES
(1, N'Khong hanh', 2, 1, 45000),        -- DH1: 2x Pho bo tai = 90k
(1, NULL, 1, 3, 40000),                  -- DH1: 1x Pho ga = 40k          => Tong DH1: 130k
(2, N'Nhieu rau', 1, 4, 50000),         -- DH2: 1x Bun cha = 50k
(2, NULL, 2, 5, 30000),                  -- DH2: 2x Nem ran = 60k          => Tong DH2: 110k
(3, NULL, 1, 6, 55000),                  -- DH3: 1x Com tam SBC = 55k
(3, N'Them com', 1, 7, 45000),          -- DH3: 1x Com tam SN = 45k       => Tong DH3: 100k
(4, N'It cay', 1, 10, 250000),          -- DH4: 1x Lau thai = 250k        => Tong DH4: 250k
(5, NULL, 2, 1, 45000),                  -- DH5: 2x Pho bo tai = 90k
(5, NULL, 1, 2, 45000),                  -- DH5: 1x Pho bo chin = 45k
(5, NULL, 1, 3, 40000),                  -- DH5: 1x Pho ga = 40k           => Tong DH5: 175k
(6, NULL, 1, 6, 55000),                  -- DH6: 1x Com tam SBC = 55k      => Tong DH6: 55k
(7, NULL, 1, 8, 45000),                  -- DH7: 1x Banh mi DB = 45k       => Tong DH7: 45k
(8, NULL, 1, 5, 30000),                  -- DH8: 1x Nem ran = 30k (da huy) => Tong DH8: 30k
(9, NULL, 1, 1, 45000);                  -- DH9: 1x Pho bo tai = 45k (huy) => Tong DH9: 45k
GO

-- =============================================
-- 16. DANH_GIA
-- PK = (ID_khach_hang, ID_mon_an, Thoi_gian)
-- Cho phep 1 KH danh gia cung 1 mon nhieu lan (khac thoi gian)
-- =============================================
INSERT INTO DANH_GIA (ID_khach_hang, ID_mon_an, Thoi_gian, Binh_luan, Xep_hang) VALUES
(1, 1, '2025-09-01 14:00:00', N'Pho rat ngon, nuoc dung dam da', 5),
(1, 3, '2025-09-01 14:05:00', N'Pho ga vua an', 3),
(2, 4, '2025-09-01 15:00:00', N'Bun cha tuyet voi', 5),
(3, 6, '2025-09-02 13:00:00', N'Com tam ngon, suon mem', 4),
(4, 10, '2025-09-03 21:00:00', N'Lau ngon nhung giao hoi lau', 4),
(5, 1, '2025-09-04 14:00:00', N'Se quay lai', 5),
-- Edge case: KH An danh gia lai Pho bo tai lan 2 (PK moi cho phep)
(1, 1, '2025-09-05 10:00:00', N'Dat lan 2, van ngon nhu lan dau', 5);
GO

-- =============================================
-- 17. TAI_XE_NHAN_DON
-- PK = ID_don_hang (1 don chi 1 tai xe, quan he N:1)
-- DH7 (Cho_xac_nhan): chua co tai xe nhan - hop le theo quy trinh
-- DH8, DH9 (Da_huy): chua co tai xe nhan - don bi huy truoc khi giao
-- =============================================
INSERT INTO TAI_XE_NHAN_DON (ID_don_hang, ID_tai_xe, Trang_thai_don, Thoi_gian_nhan_don, Thoi_gian_tra_don) VALUES
(1, 11, N'Da_giao',   '2025-09-01 12:20:00', '2025-09-01 12:50:00'),
(2, 12, N'Da_giao',   '2025-09-01 12:50:00', '2025-09-01 13:20:00'),
(3, 14, N'Da_giao',   '2025-09-02 10:35:00', '2025-09-02 11:10:00'),
(4, 11, N'Dang_giao', '2025-09-03 18:35:00', NULL),  -- TX Manh dang giao DH4
(5, 12, N'Da_giao',   '2025-09-04 11:50:00', '2025-09-04 12:15:00'),
(6, 14, N'Da_giao',   '2025-09-04 12:20:00', '2025-09-04 12:50:00');
GO

PRINT N'=== NHAP DU LIEU MAU THANH CONG ===';
GO
