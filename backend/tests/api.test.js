const request = require('supertest');
const app = require('../server');

// Mock the DB module so we can test the API layer thoroughly without needing a live SQL Server
jest.mock('../db', () => {
    const mssql = require('mssql');
    const mockRequest = {
        input: jest.fn().mockReturnThis(),
        execute: jest.fn()
    };
    const mockPool = {
        request: jest.fn(() => mockRequest)
    };
    return {
        sql: mssql,
        poolPromise: Promise.resolve(mockPool)
    };
});

const { poolPromise } = require('../db');

describe('API Quản lý Món Ăn (CRUD)', () => {
    let mockReq;
    beforeEach(async () => {
        jest.clearAllMocks();
        const pool = await poolPromise;
        mockReq = pool.request();
    });

    test('POST /api/mon-an - Thêm món ăn THÀNH CÔNG', async () => {
        // Giả lập DB thực thi thành công
        mockReq.execute.mockResolvedValue({ recordset: [] });

        const res = await request(app).post('/api/mon-an').send({
            id_nha_hang: 1,
            ten: 'Phở Bò Kobe',
            mo_ta: 'Phở bò cao cấp',
            gia_co_ban: 500000,
            trang_thai: 'Dang_ban'
        });

        expect(res.statusCode).toBe(201);
        expect(res.body.success).toBe(true);
        expect(mockReq.input).toHaveBeenCalledWith('Ten', expect.anything(), 'Phở Bò Kobe');
        expect(mockReq.execute).toHaveBeenCalledWith('sp_InsertMonAn');
    });

    test('POST /api/mon-an - THẤT BẠI (Giá âm -> Lỗi từ Database)', async () => {
        // Giả lập SQL Server throw RAISERROR do giá âm
        mockReq.execute.mockRejectedValue(new Error('Giá món ăn phải lớn hơn 0'));

        const res = await request(app).post('/api/mon-an').send({
            id_nha_hang: 1,
            ten: 'Bún Chả',
            gia_co_ban: -50000 // Invalid price
        });

        expect(res.statusCode).toBe(400); // Bad Request
        expect(res.body.success).toBe(false);
        expect(res.body.error).toBe('Giá món ăn phải lớn hơn 0');
    });

    test('DELETE /api/mon-an/:id - Xóa THẤT BẠI (Đang nằm trong đơn hàng)', async () => {
        mockReq.execute.mockRejectedValue(new Error('Lỗi nghiệp vụ: Món ăn đã nằm trong đơn hàng, không được phép xóa!'));

        const res = await request(app).delete('/api/mon-an/5');

        expect(res.statusCode).toBe(400);
        expect(res.body.success).toBe(false);
        expect(res.body.error).toContain('không được phép xóa');
    });
});

describe('API Thống Kê & Truy Vấn', () => {
    let mockReq;
    beforeEach(async () => {
        jest.clearAllMocks();
        const pool = await poolPromise;
        mockReq = pool.request();
    });

    test('GET /api/khach-hang/:id/lich-su-don-hang - Xem lịch sử thành công', async () => {
        const mockData = [
            { MaDonHang: 1, TongTien: 150000, TrangThai: 'Da_giao' }
        ];
        mockReq.execute.mockResolvedValue({ recordset: mockData });

        const res = await request(app)
            .get('/api/khach-hang/10/lich-su-don-hang')
            .query({ tu_ngay: '2025-01-01', den_ngay: '2025-12-31' });

        expect(res.statusCode).toBe(200);
        expect(res.body.success).toBe(true);
        expect(res.body.data.length).toBe(1);
        expect(mockReq.input).toHaveBeenCalledWith('ID_khach_hang', expect.anything(), '10');
    });
});
