-- =============================================
-- BTL2 - HE CO SO DU LIEU - HK252
-- Nhom 4 - Lop L04
-- Chu de: Logistic Giao Do An
-- File 3: Procedure CRUD cho bang MON_AN
-- Gom: sp_InsertMonAn, sp_UpdateMonAn, sp_DeleteMonAn
-- Nguoi thuc hien: Person 2
--
-- Rang buoc ngu nghia duoc kiem tra trong procedure:
--   - Ten mon an khong duoc trung trong cung mot nha hang
--   - Mon an bat buoc phai co nhan vien duyet (ID_nguoi_duyet NOT NULL)
--   - Khong xoa mon an neu con don hang dang xu ly
-- =============================================
USE LogisticGiaoDoAn;
GO

-- =============================================
-- 3.1 PROCEDURE THEM MON AN (sp_InsertMonAn)
-- Muc dich: Them mon an moi vao nha hang sau khi da duoc NV duyet
-- =============================================
IF OBJECT_ID('sp_InsertMonAn', 'P') IS NOT NULL DROP PROCEDURE sp_InsertMonAn;
GO

CREATE PROCEDURE sp_InsertMonAn
    @ID_nha_hang INT,
    @Ten NVARCHAR(200),
    @Gia DECIMAL(18,2),
    @ID_nguoi_duyet INT  -- BAT BUOC (schema: NOT NULL)
AS
BEGIN
    SET NOCOUNT ON;

    -- === VALIDATION ===

    -- V1: Ten mon an khong duoc rong
    IF @Ten IS NULL OR LTRIM(RTRIM(@Ten)) = ''
    BEGIN
        RAISERROR(N'Loi: Ten mon an khong duoc de trong.', 16, 1);
        RETURN;
    END

    -- V2: Gia phai lon hon 0
    IF @Gia IS NULL OR @Gia <= 0
    BEGIN
        DECLARE @giaStr NVARCHAR(50) = CAST(ISNULL(@Gia, 0) AS NVARCHAR(50));
        RAISERROR(N'Loi: Gia mon an phai lon hon 0. Gia nhap vao: %s', 16, 1, @giaStr);
        RETURN;
    END

    -- V3: Nha hang phai ton tai
    IF NOT EXISTS (SELECT 1 FROM NHA_HANG WHERE ID_nha_hang = @ID_nha_hang)
    BEGIN
        DECLARE @nhMsg NVARCHAR(200) = N'Loi: Nha hang voi ID = ' + CAST(@ID_nha_hang AS NVARCHAR) + N' khong ton tai.';
        RAISERROR(@nhMsg, 16, 1);
        RETURN;
    END

    -- V4: Nguoi duyet khong duoc NULL (bat buoc theo schema)
    IF @ID_nguoi_duyet IS NULL
    BEGIN
        RAISERROR(N'Loi: Nguoi duyet (ID_nguoi_duyet) la bat buoc. Mon an phai duoc nhan vien duyet truoc khi them vao he thong.', 16, 1);
        RETURN;
    END

    -- V5: Nguoi duyet phai la nhan vien hop le
    IF NOT EXISTS (SELECT 1 FROM NHAN_VIEN WHERE ID = @ID_nguoi_duyet)
    BEGIN
        DECLARE @nvMsg NVARCHAR(200) = N'Loi: Nguoi duyet voi ID = ' + CAST(@ID_nguoi_duyet AS NVARCHAR) + N' khong phai la nhan vien hop le.';
        RAISERROR(@nvMsg, 16, 1);
        RETURN;
    END

    -- V6: Rang buoc ngu nghia - Khong trung ten mon an trong cung nha hang
    IF EXISTS (SELECT 1 FROM MON_AN WHERE Ten = @Ten AND ID_nha_hang = @ID_nha_hang)
    BEGIN
        RAISERROR(N'Loi: Mon an "%s" da ton tai trong nha hang nay. Moi nha hang khong duoc co 2 mon trung ten.', 16, 1, @Ten);
        RETURN;
    END

    -- === THUC HIEN (voi xu ly loi nang cao) ===
    BEGIN TRY
        INSERT INTO MON_AN (ID_nha_hang, Ten, Gia, ID_nguoi_duyet)
        VALUES (@ID_nha_hang, @Ten, @Gia, @ID_nguoi_duyet);

        PRINT N'Them mon an thanh cong. ID = ' + CAST(SCOPE_IDENTITY() AS NVARCHAR);
    END TRY
    BEGIN CATCH
        DECLARE @errMsg1 NVARCHAR(4000) = N'Loi khi them mon an: ' + ERROR_MESSAGE();
        DECLARE @errSev1 INT = ERROR_SEVERITY();
        DECLARE @errSta1 INT = ERROR_STATE();
        RAISERROR(@errMsg1, @errSev1, @errSta1);
    END CATCH
END
GO

-- =============================================
-- 3.2 PROCEDURE CAP NHAT MON AN (sp_UpdateMonAn)
-- Muc dich: Cap nhat thong tin mon an (chi truong duoc truyen vao)
-- Dung ISNULL(@param, cot_cu) de giu nguyen truong khong truyen
-- =============================================
IF OBJECT_ID('sp_UpdateMonAn', 'P') IS NOT NULL DROP PROCEDURE sp_UpdateMonAn;
GO

CREATE PROCEDURE sp_UpdateMonAn
    @ID INT,
    @Ten NVARCHAR(200) = NULL,
    @Gia DECIMAL(18,2) = NULL,
    @ID_nha_hang INT = NULL,
    @ID_nguoi_duyet INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- === VALIDATION ===

    -- V1: Mon an phai ton tai
    IF NOT EXISTS (SELECT 1 FROM MON_AN WHERE ID = @ID)
    BEGIN
        DECLARE @maMsg NVARCHAR(200) = N'Loi: Mon an voi ID = ' + CAST(@ID AS NVARCHAR) + N' khong ton tai.';
        RAISERROR(@maMsg, 16, 1);
        RETURN;
    END

    -- V2: Ten khong duoc rong (neu truyen vao)
    IF @Ten IS NOT NULL AND LTRIM(RTRIM(@Ten)) = ''
    BEGIN
        RAISERROR(N'Loi: Ten mon an khong duoc de trong.', 16, 1);
        RETURN;
    END

    -- V3: Gia phai lon hon 0 (neu truyen vao)
    IF @Gia IS NOT NULL AND @Gia <= 0
    BEGIN
        RAISERROR(N'Loi: Gia mon an phai lon hon 0.', 16, 1);
        RETURN;
    END

    -- V4: Nha hang phai ton tai (neu truyen vao)
    IF @ID_nha_hang IS NOT NULL AND NOT EXISTS (SELECT 1 FROM NHA_HANG WHERE ID_nha_hang = @ID_nha_hang)
    BEGIN
        DECLARE @nhMsg NVARCHAR(200) = N'Loi: Nha hang voi ID = ' + CAST(@ID_nha_hang AS NVARCHAR) + N' khong ton tai.';
        RAISERROR(@nhMsg, 16, 1);
        RETURN;
    END

    -- V5: Nguoi duyet phai la nhan vien (neu truyen vao)
    IF @ID_nguoi_duyet IS NOT NULL AND NOT EXISTS (SELECT 1 FROM NHAN_VIEN WHERE ID = @ID_nguoi_duyet)
    BEGIN
        DECLARE @nvMsg NVARCHAR(200) = N'Loi: Nguoi duyet voi ID = ' + CAST(@ID_nguoi_duyet AS NVARCHAR) + N' khong phai nhan vien.';
        RAISERROR(@nvMsg, 16, 1);
        RETURN;
    END

    -- V6: Rang buoc ngu nghia - Khong trung ten trong cung nha hang khi doi ten
    IF @Ten IS NOT NULL
    BEGIN
        DECLARE @NhaHangHienTai INT;
        SELECT @NhaHangHienTai = ISNULL(@ID_nha_hang, ID_nha_hang) FROM MON_AN WHERE ID = @ID;

        IF EXISTS (
            SELECT 1 FROM MON_AN
            WHERE Ten = @Ten AND ID_nha_hang = @NhaHangHienTai AND ID <> @ID
        )
        BEGIN
            RAISERROR(N'Loi: Mon an "%s" da ton tai trong nha hang nay. Khong the doi trung ten.', 16, 1, @Ten);
            RETURN;
        END
    END

    -- Canh bao neu mon da co trong don hang hoan thanh (gia chot khong bi anh huong)
    IF @Gia IS NOT NULL AND EXISTS (
        SELECT 1 FROM CHI_TIET_DON_HANG ct
        JOIN DON_HANG dh ON ct.ID_don_hang = dh.ID
        WHERE ct.ID_mon_an = @ID AND dh.Trang_thai IN (N'Da_giao', N'Da_huy')
    )
    BEGIN
        PRINT N'Canh bao: Mon an nay da co trong don hang da hoan thanh. Gia chot trong don cu khong bi anh huong.';
    END

    -- === THUC HIEN ===
    BEGIN TRY
        UPDATE MON_AN
        SET Ten = ISNULL(@Ten, Ten),
            Gia = ISNULL(@Gia, Gia),
            ID_nha_hang = ISNULL(@ID_nha_hang, ID_nha_hang),
            ID_nguoi_duyet = ISNULL(@ID_nguoi_duyet, ID_nguoi_duyet)
        WHERE ID = @ID;

        PRINT N'Cap nhat mon an ID = ' + CAST(@ID AS NVARCHAR) + N' thanh cong.';
    END TRY
    BEGIN CATCH
        DECLARE @errMsg2 NVARCHAR(4000) = N'Loi khi cap nhat mon an: ' + ERROR_MESSAGE();
        DECLARE @errSev2 INT = ERROR_SEVERITY();
        DECLARE @errSta2 INT = ERROR_STATE();
        RAISERROR(@errMsg2, @errSev2, @errSta2);
    END CATCH
END
GO

-- =============================================
-- 3.3 PROCEDURE XOA MON AN (sp_DeleteMonAn)
-- Muc dich: Xoa mon an khi nha hang ngung kinh doanh mon do
-- Dieu kien: KHONG xoa neu mon an dang nam trong don hang chua hoan thanh
-- Khi xoa: dung TRANSACTION dam bao tinh toan ven (xoa cascade cac bang lien quan)
-- Cac bang bi anh huong: KHUYEN_MAI_CHO_MON_AN, MON_AN_TRONG_GIO_HANG,
--                        DANH_GIA, CHI_TIET_DON_HANG (chi don Da_giao/Da_huy)
-- =============================================
IF OBJECT_ID('sp_DeleteMonAn', 'P') IS NOT NULL DROP PROCEDURE sp_DeleteMonAn;
GO

CREATE PROCEDURE sp_DeleteMonAn
    @ID INT
AS
BEGIN
    SET NOCOUNT ON;

    -- === VALIDATION ===

    -- V1: Mon an phai ton tai
    IF NOT EXISTS (SELECT 1 FROM MON_AN WHERE ID = @ID)
    BEGIN
        DECLARE @maMsg NVARCHAR(200) = N'Loi: Mon an voi ID = ' + CAST(@ID AS NVARCHAR) + N' khong ton tai.';
        RAISERROR(@maMsg, 16, 1);
        RETURN;
    END

    -- V2: Khong xoa neu mon an con trong don hang dang xu ly
    IF EXISTS (
        SELECT 1 FROM CHI_TIET_DON_HANG ct
        JOIN DON_HANG dh ON ct.ID_don_hang = dh.ID
        WHERE ct.ID_mon_an = @ID
        AND dh.Trang_thai NOT IN (N'Da_giao', N'Da_huy')
    )
    BEGIN
        RAISERROR(N'Loi: Khong the xoa mon an vi dang co don hang chua hoan thanh chua mon nay. Hay doi don hang hoan thanh hoac huy truoc.', 16, 1);
        RETURN;
    END

    -- === THUC HIEN XOA (dung Transaction dam bao toan ven) ===
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Buoc 1: Xoa khuyen mai lien ket voi mon an
        DELETE FROM KHUYEN_MAI_CHO_MON_AN WHERE ID_mon_an = @ID;

        -- Buoc 2: Xoa mon an khoi gio hang
        DELETE FROM MON_AN_TRONG_GIO_HANG WHERE ID_mon_an = @ID;

        -- Buoc 3: Xoa danh gia cua mon an
        DELETE FROM DANH_GIA WHERE ID_mon_an = @ID;

        -- Buoc 4: Xoa chi tiet don hang (chi don da hoan thanh/da huy)
        DELETE FROM CHI_TIET_DON_HANG WHERE ID_mon_an = @ID;

        -- Buoc 5: Xoa mon an
        DELETE FROM MON_AN WHERE ID = @ID;

        COMMIT TRANSACTION;
        PRINT N'Xoa mon an ID = ' + CAST(@ID AS NVARCHAR) + N' thanh cong (da xoa cascade cac du lieu lien quan).';
    END TRY
    BEGIN CATCH
        -- Rollback neu co bat ky loi nao trong qua trinh xoa
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @errMsg3 NVARCHAR(4000) = N'Loi khi xoa mon an: ' + ERROR_MESSAGE();
        DECLARE @errSev3 INT = ERROR_SEVERITY();
        DECLARE @errSta3 INT = ERROR_STATE();
        RAISERROR(@errMsg3, @errSev3, @errSta3);
    END CATCH
END
GO

-- =============================================
-- TEST CASES minh hoa (Person 2)
-- Chay sau khi da chay 01_create_tables.sql va 02_sample_data.sql
-- =============================================

-- === sp_InsertMonAn ===
-- Test 1: INSERT thanh cong - them mon moi vao NH1
-- EXEC sp_InsertMonAn @ID_nha_hang = 1, @Ten = N'Pho bo vien', @Gia = 50000, @ID_nguoi_duyet = 7;

-- Test 2: INSERT loi - gia am
-- EXEC sp_InsertMonAn @ID_nha_hang = 1, @Ten = N'Test', @Gia = -10000, @ID_nguoi_duyet = 7;

-- Test 3: INSERT loi - nha hang khong ton tai
-- EXEC sp_InsertMonAn @ID_nha_hang = 999, @Ten = N'Test', @Gia = 50000, @ID_nguoi_duyet = 7;

-- Test 4: INSERT loi - thieu nguoi duyet (NULL)
-- EXEC sp_InsertMonAn @ID_nha_hang = 1, @Ten = N'Test', @Gia = 50000, @ID_nguoi_duyet = NULL;

-- Test 5: INSERT loi - nguoi duyet la khach hang (ID=1), khong phai nhan vien
-- EXEC sp_InsertMonAn @ID_nha_hang = 1, @Ten = N'Test', @Gia = 50000, @ID_nguoi_duyet = 1;

-- Test 6: INSERT loi - trung ten mon an trong cung nha hang (rang buoc ngu nghia)
-- EXEC sp_InsertMonAn @ID_nha_hang = 1, @Ten = N'Pho bo tai', @Gia = 50000, @ID_nguoi_duyet = 7;

-- === sp_UpdateMonAn ===
-- Test 7: UPDATE thanh cong - doi gia
-- EXEC sp_UpdateMonAn @ID = 1, @Gia = 48000;

-- Test 8: UPDATE loi - mon an khong ton tai
-- EXEC sp_UpdateMonAn @ID = 999, @Gia = 48000;

-- Test 9: UPDATE loi - trung ten trong cung NH (doi MA1 thanh ten giong MA2)
-- EXEC sp_UpdateMonAn @ID = 1, @Ten = N'Pho bo chin';

-- Test 10: UPDATE thanh cong - doi ten khong trung
-- EXEC sp_UpdateMonAn @ID = 1, @Ten = N'Pho bo tai dac biet';

-- === sp_DeleteMonAn ===
-- Test 11: DELETE loi - MA8 nam trong DH7 (Cho_xac_nhan, chua hoan thanh)
-- EXEC sp_DeleteMonAn @ID = 8;

-- Test 12: DELETE thanh cong - MA12 (Tom nuong) khong nam trong don hang nao
-- EXEC sp_DeleteMonAn @ID = 12;

-- Test 13: DELETE thanh cong - MA11 (Lau kim chi) khong nam trong don hang nao
-- EXEC sp_DeleteMonAn @ID = 11;

PRINT N'=== TAO PROCEDURE CRUD CHO MON_AN THANH CONG ===';
GO
