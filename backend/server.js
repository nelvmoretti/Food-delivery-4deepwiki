const express = require('express');
const cors = require('cors');
const { sql, poolPromise } = require('./db');

const app = express();

app.use(cors());
app.use(express.json());

// ==========================================
// API 1: QUẢN LÝ MÓN ĂN (CRUD)
// ==========================================

// 1.0 Lấy danh sách món ăn (có thể filter theo nhà hàng)
app.get('/api/mon-an', async (req, res) => {
    try {
        const { id_nha_hang } = req.query;

        const pool = await poolPromise;
        const request = pool.request();

        let query = `
            SELECT ma.ID, ma.Ten, ma.Gia, ma.ID_nha_hang, nh.Ten AS TenNhaHang, ma.ID_nguoi_duyet
            FROM MON_AN ma
            JOIN NHA_HANG nh ON ma.ID_nha_hang = nh.ID_nha_hang
        `;

        if (id_nha_hang) {
            query += ` WHERE ma.ID_nha_hang = @ID_nha_hang`;
            request.input('ID_nha_hang', sql.Int, id_nha_hang);
        }

        query += ` ORDER BY ma.ID DESC`;

        const result = await request.query(query);
        res.status(200).json({ success: true, data: result.recordset });
    } catch (err) {
        res.status(500).json({ success: false, error: err.message });
    }
});

// 1.0b Lấy danh sách nhà hàng (cho dropdown)
app.get('/api/nha-hang', async (req, res) => {
    try {
        const pool = await poolPromise;
        const result = await pool.request().query('SELECT ID_nha_hang, Ten, Dia_chi FROM NHA_HANG ORDER BY Ten');
        res.status(200).json({ success: true, data: result.recordset });
    } catch (err) {
        res.status(500).json({ success: false, error: err.message });
    }
});

// 1.1 Thêm món ăn mới — params khớp sp_InsertMonAn(@ID_nha_hang, @Ten, @Gia, @ID_nguoi_duyet)
app.post('/api/mon-an', async (req, res) => {
    try {
        const { id_nha_hang, ten, gia, id_nguoi_duyet } = req.body;

        const pool = await poolPromise;
        const request = pool.request();

        request.input('ID_nha_hang', sql.Int, id_nha_hang);
        request.input('Ten', sql.NVarChar(200), ten);
        request.input('Gia', sql.Decimal(18,2), gia);
        request.input('ID_nguoi_duyet', sql.Int, id_nguoi_duyet || null);

        await request.execute('sp_InsertMonAn');

        res.status(201).json({ success: true, message: 'Thêm món ăn thành công' });
    } catch (err) {
        res.status(400).json({ success: false, error: err.message });
    }
});

// 1.2 Cập nhật món ăn — params khớp sp_UpdateMonAn(@ID, @Ten, @Gia, @ID_nha_hang, @ID_nguoi_duyet)
app.put('/api/mon-an/:id', async (req, res) => {
    try {
        const { ten, gia, id_nha_hang, id_nguoi_duyet } = req.body;

        const pool = await poolPromise;
        const request = pool.request();

        request.input('ID', sql.Int, req.params.id);
        request.input('Ten', sql.NVarChar(200), ten || null);
        request.input('Gia', sql.Decimal(18,2), gia || null);
        request.input('ID_nha_hang', sql.Int, id_nha_hang || null);
        request.input('ID_nguoi_duyet', sql.Int, id_nguoi_duyet || null);

        await request.execute('sp_UpdateMonAn');

        res.status(200).json({ success: true, message: 'Cập nhật món ăn thành công' });
    } catch (err) {
        res.status(400).json({ success: false, error: err.message });
    }
});

// 1.3 Xóa món ăn — params khớp sp_DeleteMonAn(@ID)
app.delete('/api/mon-an/:id', async (req, res) => {
    try {
        const pool = await poolPromise;
        const request = pool.request();

        request.input('ID', sql.Int, req.params.id);
        await request.execute('sp_DeleteMonAn');

        res.status(200).json({ success: true, message: 'Xóa món ăn thành công' });
    } catch (err) {
        res.status(400).json({ success: false, error: err.message });
    }
});

// ==========================================
// API 2: TRUY VẤN VÀ THỐNG KÊ
// ==========================================

// 2.1 Xem lịch sử đơn hàng của khách
app.get('/api/khach-hang/:id/lich-su-don-hang', async (req, res) => {
    try {
        const { tu_ngay, den_ngay } = req.query; // Format: YYYY-MM-DD

        const pool = await poolPromise;
        const request = pool.request();

        request.input('ID_khach_hang', sql.Int, req.params.id);
        request.input('TuNgay', sql.DateTime, tu_ngay);
        request.input('DenNgay', sql.DateTime, den_ngay);

        const result = await request.execute('sp_LichSuDonHangCuaKhach');

        res.status(200).json({ success: true, data: result.recordset });
    } catch (err) {
        res.status(500).json({ success: false, error: err.message });
    }
});

// 2.2 Thống kê doanh thu nhà hàng
app.get('/api/thong-ke/doanh-thu-nha-hang', async (req, res) => {
    try {
        const { tu_ngay, den_ngay, muc_toi_thieu } = req.query;

        const pool = await poolPromise;
        const request = pool.request();

        request.input('TuNgay', sql.DateTime, tu_ngay);
        request.input('DenNgay', sql.DateTime, den_ngay);
        request.input('DoanhThuToiThieu', sql.Decimal(18,2), muc_toi_thieu || 0);

        const result = await request.execute('sp_ThongKeNhaHangDoanhThuCao');

        res.status(200).json({ success: true, data: result.recordset });
    } catch (err) {
        res.status(500).json({ success: false, error: err.message });
    }
});

// ==========================================
// API 3: FUNCTIONS — Gọi fn_TinhDoanhThu và fn_XepHangKhachHang
// ==========================================

// 3.1 Tính doanh thu nhà hàng
app.get('/api/fn/doanh-thu', async (req, res) => {
    try {
        const { id_nha_hang, tu_ngay, den_ngay } = req.query;

        if (!id_nha_hang || !tu_ngay || !den_ngay) {
            return res.status(400).json({ success: false, error: 'Thiếu tham số: id_nha_hang, tu_ngay, den_ngay' });
        }

        const pool = await poolPromise;
        const result = await pool.request()
            .input('ID_nha_hang', sql.Int, id_nha_hang)
            .input('TuNgay', sql.DateTime, tu_ngay)
            .input('DenNgay', sql.DateTime, den_ngay)
            .query(`SELECT dbo.fn_TinhDoanhThu(@ID_nha_hang, @TuNgay, @DenNgay) AS DoanhThu`);

        const doanhThu = result.recordset[0].DoanhThu;

        if (doanhThu === -1) {
            return res.status(400).json({ success: false, error: 'Ngày bắt đầu lớn hơn ngày kết thúc' });
        }
        if (doanhThu === -2) {
            return res.status(404).json({ success: false, error: 'Nhà hàng không tồn tại' });
        }

        res.status(200).json({ success: true, data: { doanhThu } });
    } catch (err) {
        res.status(500).json({ success: false, error: err.message });
    }
});

// 3.2 Xếp hạng khách hàng
app.get('/api/fn/xep-hang', async (req, res) => {
    try {
        const { id_khach_hang } = req.query;

        if (!id_khach_hang) {
            return res.status(400).json({ success: false, error: 'Thiếu tham số: id_khach_hang' });
        }

        const pool = await poolPromise;
        const result = await pool.request()
            .input('ID_khach_hang', sql.Int, id_khach_hang)
            .query(`SELECT dbo.fn_XepHangKhachHang(@ID_khach_hang) AS XepHang`);

        const xepHang = result.recordset[0].XepHang;

        if (xepHang === -1) {
            return res.status(404).json({ success: false, error: 'Khách hàng không tồn tại' });
        }

        res.status(200).json({ success: true, data: { xepHang } });
    } catch (err) {
        res.status(500).json({ success: false, error: err.message });
    }
});

module.exports = app;
