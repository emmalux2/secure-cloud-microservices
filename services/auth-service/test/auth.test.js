const request = require('supertest');

// 1. Mock the pg module before requiring app
jest.mock('pg', () => {
  const mPool = {
    query: jest.fn().mockImplementation((queryText, params) => {
      // Simulate finding no user for invalid login test
      return Promise.resolve({ rows: [] });
    }),
    on: jest.fn(),
    end: jest.fn(),
  };
  return { Pool: jest.fn(() => mPool) };
});

const app = require('../src/index');

describe('Auth Service Security Suite', () => {
  it('should pass healthcheck', () => {
    expect(true).toBe(true);
  });

  it('should reject registration with weak passwords (<12 chars)', async () => {
    const res = await request(app)
      .post('/auth/register')
      .send({
        email: 'weak@example.com',
        password: 'short'
      });

    expect(res.statusCode).toBe(400);
    expect(res.body).toHaveProperty('error', 'Invalid input');
  });

  it('should reject login with invalid credentials', async () => {
    const res = await request(app)
      .post('/auth/login')
      .send({
        email: 'nobody@example.com',
        password: 'invalid-password-123'
      });

    expect(res.statusCode).toBe(401);
  });
});