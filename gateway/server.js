const express = require("express");
const cors = require("cors");

const {
  createProxyMiddleware
} = require("http-proxy-middleware");

const app = express();

const PORT =
  process.env.PORT ||
  8080;


// ============================
// Backend Services
// ============================

const AUTH_SERVICE =
  process.env.AUTH_SERVICE ||
  "http://localhost:3001";

const STUDENT_SERVICE =
  process.env.STUDENT_SERVICE ||
  "http://localhost:3002";

const CONTENT_SERVICE =
  process.env.CONTENT_SERVICE ||
  "http://localhost:3003";

const PROGRESS_SERVICE =
  process.env.PROGRESS_SERVICE ||
  "http://localhost:3004";


// ============================
// Middleware
// ============================

app.use(cors());


// ============================
// Gateway Health Check
// ============================

app.get("/health", (req, res) => {
  res.json({
    service: "api-gateway",
    status: "healthy"
  });
});


// ============================
// Auth Service
// ============================
//
// Public:
// POST /api/auth/register
// POST /api/auth/login
//
// Internal:
// POST /register
// POST /login
//

app.use(
  "/api/auth",

  createProxyMiddleware({
    target: AUTH_SERVICE,
    changeOrigin: true,

    pathRewrite: (path, req) => {
      return req.originalUrl.replace(
        /^\/api\/auth/,
        ""
      );
    }
  })
);


// ============================
// Student Service
// ============================
//
// Public:
// POST /api/students
// GET  /api/students
// GET  /api/students/:userId
//
// Internal:
// POST /students
// GET  /students
// GET  /students/:userId
//

app.use(
  "/api/students",

  createProxyMiddleware({
    target: STUDENT_SERVICE,
    changeOrigin: true,

    pathRewrite: (path, req) => {
      return req.originalUrl.replace(
        /^\/api/,
        ""
      );
    }
  })
);


// ============================
// Content Service
// ============================
//
// Public:
// GET /api/content
// GET /api/content/:grade
//
// Internal:
// GET /content
// GET /content/:grade
//

app.use(
  "/api/content",

  createProxyMiddleware({
    target: CONTENT_SERVICE,
    changeOrigin: true,

    pathRewrite: (path, req) => {
      return req.originalUrl.replace(
        /^\/api/,
        ""
      );
    }
  })
);


// ============================
// Progress Service
// ============================
//
// Public:
// GET  /api/progress/:userId
// POST /api/progress/check-access
// POST /api/progress/complete
//
// Internal:
// GET  /progress/:userId
// POST /progress/check-access
// POST /progress/complete
//

app.use(
  "/api/progress",

  createProxyMiddleware({
    target: PROGRESS_SERVICE,
    changeOrigin: true,

    pathRewrite: (path, req) => {
      return req.originalUrl.replace(
        /^\/api/,
        ""
      );
    }
  })
);


// ============================
// 404
// ============================

app.use((req, res) => {
  res.status(404).json({
    message: "Gateway route not found"
  });
});


// ============================
// Start Gateway
// ============================

app.listen(
  PORT,
  "0.0.0.0",
  () => {
    console.log(
      `api-gateway running on port ${PORT}`
    );

    console.log(
      `AUTH_SERVICE=${AUTH_SERVICE}`
    );

    console.log(
      `STUDENT_SERVICE=${STUDENT_SERVICE}`
    );

    console.log(
      `CONTENT_SERVICE=${CONTENT_SERVICE}`
    );

    console.log(
      `PROGRESS_SERVICE=${PROGRESS_SERVICE}`
    );
  }
);
