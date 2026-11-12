<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>MyRepairHub — Admin Panel</title>
    <link rel="icon" type="image/x-icon" href="/favicon.ico">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --primary: #2563eb;
            --primary-hover: #1d4ed8;
            --bg-dark: #0f172a;
            --bg-card: #1e293b;
            --bg-body: #f8fafc;
            --text-main: #0f172a;
            --text-muted: #64748b;
            --border-color: #e2e8f0;
            --success: #16a34a;
            --warning: #d97706;
            --danger: #dc2626;
            --sidebar-width: 250px;
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
            font-family: 'Inter', sans-serif;
        }

        body {
            background-color: var(--bg-body);
            color: var(--text-main);
            height: 100vh;
            display: flex;
            overflow: hidden;
        }

        /* --- AUTH LOGIN SCREEN --- */
        #auth-screen {
            position: fixed;
            inset: 0;
            background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
            display: flex;
            align-items: center;
            justify-content: center;
            z-index: 1000;
        }

        .login-card {
            background: #ffffff;
            width: 100%;
            max-width: 420px;
            padding: 36px;
            border-radius: 16px;
            box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.2), 0 10px 10px -5px rgba(0, 0, 0, 0.1);
        }

        .login-header {
            text-align: center;
            margin-bottom: 24px;
        }

        .login-header h2 {
            font-size: 22px;
            font-weight: 700;
            color: #0f172a;
        }

        .login-header p {
            font-size: 13px;
            color: #64748b;
            margin-top: 4px;
        }

        .form-group {
            margin-bottom: 18px;
        }

        .form-group label {
            display: block;
            font-size: 12px;
            font-weight: 600;
            text-transform: uppercase;
            color: #475569;
            margin-bottom: 6px;
        }

        .form-control {
            width: 100%;
            padding: 12px 14px;
            border: 1px solid #cbd5e1;
            border-radius: 8px;
            font-size: 14px;
            outline: none;
            transition: border 0.2s;
        }

        .form-control:focus {
            border-color: var(--primary);
            box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.15);
        }

        .btn-primary {
            width: 100%;
            padding: 12px;
            background: var(--primary);
            color: white;
            border: none;
            border-radius: 8px;
            font-weight: 600;
            font-size: 14px;
            cursor: pointer;
            transition: background 0.2s;
        }

        .btn-primary:hover {
            background: var(--primary-hover);
        }

        .alert-error {
            background: #fef2f2;
            border: 1px solid #fecaca;
            color: #991b1b;
            padding: 10px 14px;
            border-radius: 8px;
            font-size: 13px;
            margin-bottom: 18px;
            display: none;
        }

        /* --- LAYOUT SIDEBAR & MAIN --- */
        #app-layout {
            display: flex;
            width: 100vw;
            height: 100vh;
            position: relative;
        }

        .sidebar {
            width: var(--sidebar-width);
            background: #0f172a;
            color: white;
            display: flex;
            flex-direction: column;
            z-index: 1050;
        }

        .sidebar-brand {
            padding: 20px;
            font-size: 18px;
            font-weight: 700;
            border-bottom: 1px solid #1e293b;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .sidebar-brand span {
            color: #38bdf8;
        }

        .sidebar-close-btn {
            display: none;
            background: none;
            border: none;
            color: #94a3b8;
            font-size: 20px;
            cursor: pointer;
        }

        .sidebar-menu {
            list-style: none;
            padding: 16px 10px;
            flex: 1;
            overflow-y: auto;
        }

        .nav-item {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 12px 14px;
            color: #94a3b8;
            text-decoration: none;
            font-size: 14px;
            font-weight: 500;
            border-radius: 8px;
            margin-bottom: 4px;
            transition: all 0.2s;
        }

        .nav-item:hover {
            background: #1e293b;
            color: white;
        }

        .nav-item.active {
            background: var(--primary);
            color: white;
        }

        .user-footer {
            padding: 16px 20px;
            border-top: 1px solid #1e293b;
            display: flex;
            align-items: center;
            justify-content: space-between;
            font-size: 13px;
        }

        .main-content {
            flex: 1;
            display: flex;
            flex-direction: column;
            overflow: hidden;
            background: #f8fafc;
        }

        .hamburger-btn {
            display: none;
            background: none;
            border: none;
            font-size: 22px;
            cursor: pointer;
            color: #0f172a;
            padding: 4px 8px;
            border-radius: 6px;
        }

        .hamburger-btn:hover {
            background: #f1f5f9;
        }

        .sidebar-overlay {
            display: none;
            position: fixed;
            inset: 0;
            background: rgba(15, 23, 42, 0.6);
            backdrop-filter: blur(3px);
            z-index: 1040;
        }

        .table-responsive {
            width: 100%;
            overflow-x: auto;
            -webkit-overflow-scrolling: touch;
            scrollbar-width: thin;
            scrollbar-color: #cbd5e1 transparent;
        }

        .table-responsive::-webkit-scrollbar {
            height: 6px;
        }

        .table-responsive::-webkit-scrollbar-track {
            background: #f8fafc;
        }

        .table-responsive::-webkit-scrollbar-thumb {
            background: #cbd5e1;
            border-radius: 6px;
        }

        .table-responsive::-webkit-scrollbar-thumb:hover {
            background: #94a3b8;
        }

        .sub-nav-bar {
            display: flex;
            gap: 4px;
            margin-bottom: 20px;
            background: #f1f5f9;
            padding: 4px;
            border-radius: 10px;
            border: 1px solid #e2e8f0;
            overflow-x: auto;
            -webkit-overflow-scrolling: touch;
            scrollbar-width: none;
            -ms-overflow-style: none;
        }

        .sub-nav-bar::-webkit-scrollbar {
            display: none;
        }

        .sub-nav-btn {
            padding: 7px 14px;
            font-size: 13px;
            font-weight: 500;
            border-radius: 7px;
            border: none;
            background: transparent;
            color: #64748b;
            cursor: pointer;
            white-space: nowrap;
            transition: all 0.15s ease-in-out;
            display: inline-flex;
            align-items: center;
            gap: 6px;
        }

        .sub-nav-btn:hover {
            background: rgba(255, 255, 255, 0.7);
            color: #0f172a;
        }

        .sub-nav-btn.active {
            background: #ffffff;
            color: #0f172a;
            font-weight: 600;
            box-shadow: 0 1px 3px rgba(0,0,0,0.08), 0 1px 2px rgba(0,0,0,0.04);
        }

        @media (max-width: 1024px) {
            .table-toolbar {
                gap: 10px;
            }
            .search-box {
                min-width: 220px;
            }
        }

        @media (max-width: 768px) {
            .hamburger-btn {
                display: block;
            }

            .sidebar-close-btn {
                display: block;
            }

            .sidebar {
                position: fixed;
                top: 0;
                left: 0;
                bottom: 0;
                transform: translateX(-100%);
                transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1);
                width: 270px;
                box-shadow: 4px 0 25px rgba(0,0,0,0.4);
            }

            .sidebar.mobile-open {
                transform: translateX(0);
            }

            .sidebar-overlay.mobile-open {
                display: block;
            }

            .topbar {
                padding: 0 16px;
                height: 56px;
            }

            .content-area {
                padding: 14px;
            }

            .grid-4 {
                grid-template-columns: repeat(2, 1fr);
                gap: 10px;
            }

            .metric-card {
                padding: 14px;
            }

            .metric-value {
                font-size: 18px;
            }

            .modal-content {
                max-width: 95%;
                margin: 10px;
            }

            .table-toolbar {
                padding: 12px;
                gap: 10px;
                flex-direction: column;
                align-items: stretch;
            }

            .search-box {
                min-width: 100%;
            }

            .filter-select {
                flex: 1;
                min-width: 140px;
            }
        }

        .topbar {
            height: 60px;
            background: #ffffff;
            border-bottom: 1px solid var(--border-color);
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 0 28px;
            position: sticky;
            top: 0;
            z-index: 100;
        }

        .topbar h1 {
            font-size: 18px;
            font-weight: 700;
            color: #0f172a;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .content-area {
            flex: 1;
            padding: 24px 28px;
            overflow-y: auto;
        }

        /* --- CARDS & TABLES --- */
        .grid-4 {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
            gap: 20px;
            margin-bottom: 24px;
        }

        .metric-card {
            background: white;
            padding: 20px;
            border-radius: 12px;
            border: 1px solid var(--border-color);
            box-shadow: 0 1px 3px rgba(0,0,0,0.05);
        }

        .metric-title {
            font-size: 12px;
            font-weight: 600;
            text-transform: uppercase;
            color: #64748b;
        }

        .metric-value {
            font-size: 24px;
            font-weight: 700;
            color: #0f172a;
            margin: 8px 0 4px 0;
        }

        .metric-sub {
            font-size: 12px;
            color: #10b981;
            font-weight: 500;
        }

        .card-table {
            background: white;
            border-radius: 14px;
            border: 1px solid var(--border-color);
            box-shadow: 0 1px 3px rgba(0,0,0,0.05);
            overflow: hidden;
        }

        .table-toolbar {
            padding: 14px 20px;
            border-bottom: 1px solid #f1f5f9;
            display: flex;
            gap: 12px;
            flex-wrap: wrap;
            align-items: center;
            justify-content: space-between;
            background: #ffffff;
        }

        .search-box {
            position: relative;
            min-width: 280px;
        }

        .search-box input {
            width: 100%;
            padding: 9px 14px 9px 38px;
            border: 1px solid #cbd5e1;
            border-radius: 8px;
            font-size: 13px;
            outline: none;
            background: #f8fafc;
            color: #0f172a;
            transition: all 0.2s;
        }

        .search-box input:focus {
            background: #ffffff;
            border-color: var(--primary);
            box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.12);
        }

        .search-box::before {
            content: '🔍';
            position: absolute;
            left: 12px;
            top: 50%;
            transform: translateY(-50%);
            font-size: 13px;
            opacity: 0.5;
            pointer-events: none;
        }

        .filter-select {
            padding: 8px 32px 8px 12px;
            border: 1px solid #cbd5e1;
            border-radius: 8px;
            font-size: 13px;
            outline: none;
            background: #f8fafc url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 24 24' fill='none' stroke='%2364748b' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='m6 9 6 6 6-6'/%3E%3C/svg%3E") no-repeat right 10px center;
            -webkit-appearance: none;
            appearance: none;
            color: #334155;
            cursor: pointer;
            font-weight: 500;
            transition: all 0.2s;
        }

        .filter-select:focus {
            background-color: #ffffff;
            border-color: var(--primary);
            box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.12);
        }

        table {
            width: 100%;
            min-width: 1050px;
            border-collapse: collapse;
            text-align: left;
            font-size: 13.5px;
        }

        th {
            background: #f8fafc;
            padding: 12px 18px;
            font-size: 11px;
            font-weight: 700;
            letter-spacing: 0.05em;
            text-transform: uppercase;
            color: #64748b;
            border-bottom: 1px solid var(--border-color);
            white-space: nowrap;
        }

        td {
            padding: 13px 18px;
            border-bottom: 1px solid #f1f5f9;
            color: #334155;
            vertical-align: middle;
        }

        tr:last-child td {
            border-bottom: none;
        }

        tr:hover td {
            background: #f8fafc;
        }

        .badge {
            display: inline-flex;
            align-items: center;
            gap: 4px;
            padding: 3px 8px;
            border-radius: 6px;
            font-size: 11px;
            font-weight: 600;
            letter-spacing: 0.02em;
            white-space: nowrap;
        }

        .badge-active { background: #dcfce7; color: #15803d; border: 1px solid #bbf7d0; }
        .badge-inactive { background: #fee2e2; color: #b91c1c; border: 1px solid #fecaca; }
        .badge-trial { background: #fef3c7; color: #b45309; border: 1px solid #fde68a; }
        .badge-resolved { background: #e0e7ff; color: #4338ca; border: 1px solid #c7d2fe; }
        .badge-blue { background: #eff6ff; color: #1d4ed8; border: 1px solid #bfdbfe; }
        .badge-purple { background: #f5f3ff; color: #6d28d9; border: 1px solid #ddd6fe; }
        .badge-emerald { background: #ecfdf5; color: #047857; border: 1px solid #a7f3d0; }

        .action-btn-group {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            white-space: nowrap;
            flex-wrap: nowrap;
        }

        .action-btn {
            display: inline-flex;
            align-items: center;
            gap: 5px;
            padding: 6px 10px;
            font-size: 12px;
            font-weight: 600;
            border-radius: 7px;
            border: 1px solid transparent;
            cursor: pointer;
            transition: all 0.15s ease-in-out;
            white-space: nowrap;
            line-height: 1.2;
            text-decoration: none;
        }

        .action-btn svg {
            width: 13px;
            height: 13px;
            flex-shrink: 0;
        }

        .action-btn-default {
            background: #ffffff;
            border-color: #cbd5e1;
            color: #334155;
        }
        .action-btn-default:hover {
            background: #f1f5f9;
            border-color: #94a3b8;
            color: #0f172a;
        }

        .action-btn-emerald {
            background: #ecfdf5;
            border-color: #a7f3d0;
            color: #047857;
        }
        .action-btn-emerald:hover {
            background: #d1fae5;
            border-color: #6ee7b7;
            color: #065f46;
        }

        .action-btn-indigo {
            background: #eef2ff;
            border-color: #c7d2fe;
            color: #4338ca;
        }
        .action-btn-indigo:hover {
            background: #e0e7ff;
            border-color: #a5b4fc;
            color: #3730a3;
        }

        .action-btn-danger {
            background: #fef2f2;
            border-color: #fecaca;
            color: #b91c1c;
        }
        .action-btn-danger:hover {
            background: #fee2e2;
            border-color: #fca5a5;
            color: #991b1b;
        }

        .action-btn-success {
            background: #f0fdf4;
            border-color: #bbf7d0;
            color: #15803d;
        }
        .action-btn-success:hover {
            background: #dcfce7;
            border-color: #86efac;
            color: #166534;
        }

        .btn-sm {
            padding: 6px 12px;
            font-size: 12px;
            font-weight: 600;
            border-radius: 6px;
            border: 1px solid #cbd5e1;
            background: white;
            color: #334155;
            cursor: pointer;
            transition: all 0.2s;
        }

        .btn-sm:hover {
            background: #f1f5f9;
        }

        .btn-danger-sm {
            background: #fef2f2;
            color: #991b1b;
            border-color: #fecaca;
        }

        .btn-danger-sm:hover {
            background: #fee2e2;
        }

        .btn-success-sm {
            background: #f0fdf4;
            color: #166534;
            border-color: #bbf7d0;
        }

        .btn-success-sm:hover {
            background: #dcfce7;
        }

        /* MODAL */
        #modal-container {
            position: fixed;
            inset: 0;
            background: rgba(15, 23, 42, 0.6);
            backdrop-filter: blur(4px);
            display: none;
            align-items: center;
            justify-content: center;
            z-index: 1100;
            padding: 24px;
            overflow-y: auto;
        }

        .modal-content {
            background: white;
            width: 100%;
            max-width: 540px;
            max-height: 90vh;
            border-radius: 14px;
            box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
            display: flex;
            flex-direction: column;
            overflow: hidden;
            margin: auto;
        }

        .modal-header {
            padding: 16px 24px;
            border-bottom: 1px solid var(--border-color);
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-shrink: 0;
            background: #ffffff;
        }

        .modal-header h3 {
            font-size: 16px;
            font-weight: 700;
            margin: 0;
        }

        .modal-close {
            background: none;
            border: none;
            font-size: 22px;
            line-height: 1;
            cursor: pointer;
            color: #64748b;
            padding: 4px;
            border-radius: 6px;
        }

        .modal-close:hover {
            color: #0f172a;
            background: #f1f5f9;
        }

        .modal-body {
            padding: 20px 24px;
            overflow-y: auto;
            flex: 1 1 auto;
        }
    </style>
</head>
<body>

    <!-- LOGIN SCREEN -->
    <div id="auth-screen">
        <div class="login-card">
            <div class="login-header">
                <img src="/logo.png" alt="MyRepairHub Logo" style="height: 64px; width: 64px; margin: 0 auto 12px auto; display: block; border-radius: 14px; box-shadow: 0 4px 14px rgba(0,0,0,0.18);">
                <h2>MyRepairHub Admin</h2>
                <p>Platform Administrator Sign In</p>
            </div>
            <div id="login-alert" class="alert-error"></div>
            <form onsubmit="handleLogin(event)">
                <div class="form-group">
                    <label>Admin Mobile / Email</label>
                    <input type="text" id="login-input" class="form-control" placeholder="Enter admin mobile or email" required>
                </div>
                <div class="form-group">
                    <label>Password</label>
                    <input type="password" id="password-input" class="form-control" placeholder="Enter admin password" required>
                </div>
                <button type="submit" id="login-submit-btn" class="btn-primary">Sign In to Dashboard</button>
            </form>
        </div>
    </div>

    <!-- SIDEBAR BACKDROP OVERLAY FOR MOBILE -->
    <div id="sidebar-overlay" class="sidebar-overlay" onclick="toggleMobileSidebar()"></div>

    <!-- MAIN APP LAYOUT -->
    <div id="app-layout" style="display: none;">
        <aside class="sidebar">
            <div class="sidebar-brand">
                <div style="display:flex; align-items:center; gap:10px;">
                    <img src="/logo.png" alt="MyRepairHub Logo" style="width:34px; height:34px; border-radius:8px; object-fit:cover;">
                    <span style="font-weight:800; font-size:18px; letter-spacing:-0.5px; color:#ffffff;">Repair<span style="color:#60a5fa;">Hub</span></span>
                </div>
                <button class="sidebar-close-btn" onclick="toggleMobileSidebar()">✕</button>
            </div>
            <ul class="sidebar-menu">
                <li><a href="#dashboard" class="nav-item active" onclick="switchNav('dashboard')">📊 Dashboard</a></li>
                <li><a href="#shops" class="nav-item" onclick="switchNav('shops')">🏪 Shops Directory</a></li>
                <li><a href="#operations" class="nav-item" onclick="switchNav('operations')">📑 Shop Operations</a></li>
                <li><a href="#used-mobiles" class="nav-item" onclick="switchNav('used-mobiles')">📱 Used Mobiles</a></li>
                <li><a href="#billing" class="nav-item" onclick="switchNav('billing')">💳 Subscriptions & Revenue</a></li>
                <li><a href="#referrals" class="nav-item" onclick="switchNav('referrals')">🎁 Referral & Points</a></li>
                <li><a href="#reports" class="nav-item" onclick="switchNav('reports')">📈 Business Reports</a></li>
                <li><a href="#notifications" class="nav-item" onclick="switchNav('notifications')"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="display:inline-block; vertical-align:-2px; margin-right:6px;"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg> Push Notifications</a></li>
                <li><a href="#settings" class="nav-item" onclick="switchNav('settings')">⚙️ System & Settings</a></li>
            </ul>
            <div class="user-footer">
                <span id="admin-name">Admin</span>
                <a href="#" style="color:#ef4444; text-decoration:none; font-weight:600;" onclick="logout()">Logout</a>
            </div>
        </aside>

        <main class="main-content">
            <header class="topbar">
                <div style="display:flex; align-items:center; gap:14px;">
                    <button class="hamburger-btn" onclick="toggleMobileSidebar()">☰</button>
                    <h1 id="page-title">Dashboard Overview</h1>
                </div>
                <div style="display:flex; align-items:center; gap:12px;">
                    <span class="badge badge-active" style="font-size:11px; padding:4px 10px;">
                        <span style="width:6px; height:6px; border-radius:50%; background:#16a34a; display:inline-block; margin-right:3px;"></span>
                        Platform Online
                    </span>
                    <a href="/" target="_blank" style="font-size:12px; color:#2563eb; font-weight:600; text-decoration:none; background:#eff6ff; border:1px solid #bfdbfe; padding:6px 12px; border-radius:8px; display:inline-flex; align-items:center; gap:6px; transition:all 0.2s;">
                        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/><polyline points="15 3 21 3 21 9"/><line x1="10" y1="14" x2="21" y2="3"/></svg>
                        View Live Site
                    </a>
                </div>
            </header>
            <div id="content-area" class="content-area">
                <!-- Dynamic Content View Loaded Here -->
            </div>
        </main>
    </div>

    <!-- GLOBAL MODAL -->
    <div id="modal-container">
        <div class="modal-content">
            <div class="modal-header">
                <h3 id="modal-title">Modal Title</h3>
                <button class="modal-close" onclick="closeModal()">✕</button>
            </div>
            <div id="modal-body" class="modal-body">
                <!-- Dynamic Modal Content -->
            </div>
        </div>
    </div>

    <script>
        const API_BASE = '/api/v1/admin';
        let authToken = localStorage.getItem('admin_token');

        document.addEventListener('DOMContentLoaded', () => {
            if (authToken) {
                checkAuth();
            } else {
                showAuthScreen();
            }
        });

        function showAuthScreen() {
            document.getElementById('auth-screen').style.display = 'flex';
            document.getElementById('app-layout').style.display = 'none';
        }

        function showAppLayout() {
            document.getElementById('auth-screen').style.display = 'none';
            document.getElementById('app-layout').style.display = 'flex';
            const initialRoute = (window.location.hash || '').replace('#', '') || 'dashboard';
            switchNav(initialRoute);
        }

        window.addEventListener('hashchange', () => {
            if (authToken) {
                const route = (window.location.hash || '').replace('#', '') || 'dashboard';
                switchNav(route);
            }
        });

        async function checkAuth() {
            const data = await apiFetch('/auth/me');
            if (data && data.success) {
                document.getElementById('admin-name').innerText = data.data.user.name || 'Admin';
                showAppLayout();
            } else {
                logout();
            }
        }

        async function handleLogin(e) {
            e.preventDefault();
            const login = document.getElementById('login-input').value.trim();
            const password = document.getElementById('password-input').value;
            const alertBox = document.getElementById('login-alert');
            const submitBtn = document.getElementById('login-submit-btn');

            alertBox.style.display = 'none';
            if (submitBtn) {
                submitBtn.disabled = true;
                submitBtn.innerText = 'Authenticating...';
            }

            try {
                const res = await fetch('/api/v1/admin/auth/login', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
                    body: JSON.stringify({ login, password })
                });
                const data = await res.json();

                if (res.ok && data.success && data.data && data.data.token) {
                    authToken = data.data.token;
                    localStorage.setItem('admin_token', authToken);
                    document.getElementById('admin-name').innerText = data.data.user.name || 'Admin';
                    showAppLayout();
                } else {
                    let errMsg = data.message || 'Invalid credentials or non-admin account';
                    if (data.errors) {
                        errMsg = Object.values(data.errors).flat().join(' ');
                    }
                    alertBox.innerText = errMsg;
                    alertBox.style.display = 'block';
                }
            } catch (err) {
                alertBox.innerText = 'Server connection error. Please try again.';
                alertBox.style.display = 'block';
            } finally {
                if (submitBtn) {
                    submitBtn.disabled = false;
                    submitBtn.innerText = 'Sign In to Dashboard';
                }
            }
        }

        function logout() {
            if (authToken) {
                apiFetch('/auth/logout', 'POST');
            }
            localStorage.removeItem('admin_token');
            authToken = null;
            showAuthScreen();
        }

        // Mobile Sidebar Toggles & Responsive Content Helper
        function toggleMobileSidebar() {
            document.querySelector('.sidebar').classList.toggle('mobile-open');
            document.getElementById('sidebar-overlay').classList.toggle('mobile-open');
        }

        function closeMobileSidebar() {
            document.querySelector('.sidebar').classList.remove('mobile-open');
            document.getElementById('sidebar-overlay').classList.remove('mobile-open');
        }

        let currentMainSection = '';

        function getContentContainer() {
            return document.getElementById('sub-content-area') || document.getElementById('content-area');
        }

        // Navigation Switcher & Section Sub-Tabs Router
        function switchNav(route, subTab = '') {
            closeMobileSidebar();

            // Map individual sub-routes to 6 main sidebar sections
            let mainSection = route;
            if (['sales', 'repairs', 'customers', 'inventory', 'expenses', 'warranties', 'technicians', 'purchases', 'vendors', 'operations'].includes(route)) {
                mainSection = 'operations';
                subTab = subTab || (route === 'operations' ? 'sales' : route);
            } else if (['used-mobiles', 'used-mobile-users', 'used-mobile-devices'].includes(route)) {
                mainSection = 'used-mobiles';
                subTab = subTab || (route === 'used-mobile-devices' ? 'devices' : 'users');
            } else if (['subscriptions', 'payments', 'plans', 'revenue', 'billing'].includes(route)) {
                mainSection = 'billing';
                subTab = subTab || (route === 'billing' ? 'subscriptions' : route);
            } else if (['pages', 'gateway', 'support', 'audit', 'users', 'version', 'notifications', 'settings'].includes(route)) {
                mainSection = 'settings';
                subTab = subTab || (route === 'settings' ? 'version' : route);
            }

            document.querySelectorAll('.nav-item').forEach(el => el.classList.remove('active'));
            const activeNav = document.querySelector(`.nav-item[href="#${route}"]`) || document.querySelector(`.nav-item[href="#${mainSection}"]`);
            if (activeNav) activeNav.classList.add('active');

            const titleMap = {
                'dashboard': 'Dashboard Overview',
                'shops': 'Shops Directory',
                'operations': 'Shop Operations Data Hub',
                'used-mobiles': '📱 Used Mobiles Feature & Adoption Hub',
                'billing': 'Subscriptions & Revenue Billing',
                'referrals': 'Referral & Points Management',
                'reports': 'Platform Business & Financial Reports',
                'settings': 'System & Platform Settings',
                'notifications': 'Broadcast Push Notifications'
            };
            document.getElementById('page-title').innerText = titleMap[route] || titleMap[mainSection] || 'Admin Panel';

            // CRITICAL FIX: Clear content-area when switching between major sections or
            // navigating to a section without sub-tabs (dashboard, shops, reports) so old sub-nav bars never linger!
            const contentArea = document.getElementById('content-area');
            if (['dashboard', 'shops', 'reports', 'referrals'].includes(mainSection) || currentMainSection !== mainSection) {
                contentArea.innerHTML = '';
            }
            currentMainSection = mainSection;

            if (mainSection === 'dashboard') {
                loadDashboardView();
            } else if (mainSection === 'shops') {
                loadShopsView();
            } else if (mainSection === 'referrals') {
                loadReferralsView();
            } else if (mainSection === 'used-mobiles') {
                renderSubNavBar('used-mobiles', subTab, [
                    { id: 'users', label: '👥 Shops Using Feature', fn: loadUsedMobileUsersView },
                    { id: 'devices', label: '📱 All Used Mobiles Ledger', fn: loadUsedMobileDevicesView },
                ]);
            } else if (mainSection === 'reports') {
                loadReportsView();
            } else if (mainSection === 'operations') {
                renderSubNavBar('operations', subTab, [
                    { id: 'sales', label: '🛒 Sales & Invoices', fn: loadSalesView },
                    { id: 'repairs', label: '🔧 Repair Jobs', fn: loadRepairsView },
                    { id: 'customers', label: '👥 Customer Directory', fn: loadCustomersView },
                    { id: 'inventory', label: '📦 Inventory Stock', fn: loadInventoryView },
                    { id: 'purchases', label: '🛍️ Purchases', fn: loadPurchasesView },
                    { id: 'vendors', label: '🏬 Vendors', fn: loadVendorsView },
                    { id: 'expenses', label: '💸 Shop Expenses', fn: loadExpensesView },
                    { id: 'warranties', label: '🛡️ Warranties', fn: loadWarrantiesView },
                    { id: 'technicians', label: '🧰 Technicians', fn: loadTechniciansView },
                    { id: 'used-mobiles-tab', label: '📱 Used Mobiles', fn: () => switchNav('used-mobiles') },
                ]);
            } else if (mainSection === 'billing') {
                renderSubNavBar('billing', subTab, [
                    { id: 'subscriptions', label: '💳 Subscriptions', fn: loadSubscriptionsView },
                    { id: 'payments', label: '🧾 Real Payments', fn: loadPaymentsView },
                    { id: 'plans', label: '🏷️ Plans & Pricing', fn: loadPlansView },
                    { id: 'revenue', label: '📈 Revenue Analytics', fn: loadRevenueView },
                ]);
            } else if (mainSection === 'settings') {
                renderSubNavBar('settings', subTab, [
                    { id: 'notifications', label: '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="display:inline-block; vertical-align:-2px; margin-right:6px;"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg> Push Notifications', fn: loadNotificationsView },
                    { id: 'version', label: '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="display:inline-block; vertical-align:-2px; margin-right:4px;"><rect x="5" y="2" width="14" height="20" rx="2" ry="2"/><line x1="12" y1="18" x2="12.01" y2="18"/></svg> App Force Update', fn: loadAppVersionView },
                    { id: 'pages', label: '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="display:inline-block; vertical-align:-2px; margin-right:4px;"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg> Legal Pages CMS', fn: loadPagesView },
                    { id: 'gateway', label: '⚙️ Gateway Settings', fn: loadGatewayView },
                    { id: 'otp', label: '🔐 OTP Settings', fn: loadOtpSettingsView },
                    { id: 'support', label: '💬 Support Tickets', fn: loadSupportView },
                    { id: 'audit', label: '🛡️ Audit Logs', fn: loadAuditView },
                    { id: 'users', label: '👥 User Accounts', fn: loadUsersView },
                ]);
            }
        }

        function renderSubNavBar(section, activeSub, tabs) {
            const contentArea = document.getElementById('content-area');
            const navHtml = `
                <div class="sub-nav-bar">
                    ${tabs.map(t => `
                        <button class="sub-nav-btn ${t.id === activeSub ? 'active' : ''}" onclick="switchNav('${section}', '${t.id}')">
                            ${t.label}
                        </button>
                    `).join('')}
                </div>
                <div id="sub-content-area"></div>
            `;
            contentArea.innerHTML = navHtml;

            const targetTab = tabs.find(t => t.id === activeSub) || tabs[0];
            if (targetTab && typeof targetTab.fn === 'function') {
                targetTab.fn();
            }
        }

        // Helper API Fetcher
        async function apiFetch(endpoint, method = 'GET', body = null) {
            const opts = {
                method,
                headers: { 'Authorization': `Bearer ${authToken}`, 'Accept': 'application/json', 'Content-Type': 'application/json' }
            };
            if (body) opts.body = JSON.stringify(body);
            const res = await fetch(`${API_BASE}${endpoint}`, opts);
            return await res.json();
        }

        let _searchDebounceTimer = null;
        function debounceSearch(fn) {
            if (_searchDebounceTimer) clearTimeout(_searchDebounceTimer);
            const activeEl = document.activeElement;
            const activeId = activeEl && activeEl.id ? activeEl.id : null;
            const selStart = activeEl && typeof activeEl.selectionStart === 'number' ? activeEl.selectionStart : null;
            const selEnd = activeEl && typeof activeEl.selectionEnd === 'number' ? activeEl.selectionEnd : null;
            _searchDebounceTimer = setTimeout(async () => {
                await fn();
                if (activeId) {
                    const nextEl = document.getElementById(activeId);
                    if (nextEl) {
                        nextEl.focus();
                        if (selStart !== null && typeof nextEl.setSelectionRange === 'function') {
                            try { nextEl.setSelectionRange(selStart, selEnd ?? selStart); } catch (_) {}
                        }
                    }
                }
            }, 400);
        }

        function renderPagination(meta, fnName, ...extraArgs) {
            if (!meta || meta.last_page <= 1) return '';
            const current = meta.current_page;
            const last = meta.last_page;
            const total = meta.total || 0;
            const from = meta.from || (((current - 1) * meta.per_page) + 1);
            const to = meta.to || Math.min(current * meta.per_page, total);
            const extraStr = extraArgs.map(a => typeof a === 'string' ? `'${a.replace(/'/g, "\'")}'` : a).join(', ');
            const comma = extraStr ? ', ' : '';

            return `
                <div style="display:flex; align-items:center; justify-content:space-between; padding:14px 20px; border-top:1px solid #e2e8f0; font-size:13px; color:#64748b; background:#f8fafc;">
                    <div>Showing <strong>${from}-${to}</strong> of <strong>${total}</strong> records</div>
                    <div style="display:flex; gap:8px; align-items:center;">
                        <button class="btn-sm" ${current <= 1 ? 'disabled style="opacity:0.4; cursor:not-allowed;"' : ''} onclick="${fnName}(${current - 1}${comma}${extraStr})">← Prev</button>
                        <span style="font-weight:600; color:#1e293b; padding:0 6px;">Page ${current} of ${last}</span>
                        <button class="btn-sm" ${current >= last ? 'disabled style="opacity:0.4; cursor:not-allowed;"' : ''} onclick="${fnName}(${current + 1}${comma}${extraStr})">Next →</button>
                    </div>
                </div>
            `;
        }

        // 1. DASHBOARD VIEW
        async function loadDashboardView() {
            const content = getContentContainer();
            content.innerHTML = '<div style="padding:20px; color:#64748b;">Loading overview metrics...</div>';
            const data = await apiFetch('/dashboard');

            if (!data.success) return;
            const m = data.data;

            content.innerHTML = `
                <div class="grid-4" style="grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));">
                    <div class="metric-card">
                        <div class="metric-title">Total Shops</div>
                        <div class="metric-value">${m.shops.total}</div>
                        <div class="metric-sub">${m.shops.active} Active | ${m.shops.new_month} New This Month</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-title">Subscriptions</div>
                        <div class="metric-value">${m.subscriptions.active}</div>
                        <div class="metric-sub">${m.subscriptions.trial} Trial | ${m.subscriptions.expired} Expired</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-title">Total Platform Revenue</div>
                        <div class="metric-value">₹${m.business.total_revenue.toLocaleString()}</div>
                        <div class="metric-sub">₹${m.business.revenue_this_month.toLocaleString()} This Month</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-title">Platform Repairs & Sales</div>
                        <div class="metric-value">${m.usage.total_repairs} Repairs</div>
                        <div class="metric-sub">${m.usage.total_sales} Total Sales Recorded</div>
                    </div>
                    <div class="metric-card" style="border-left:4px solid #10b981; cursor:pointer; transition:all 0.2s; position:relative;" onclick="showAppOpensTodayModal()" title="Click to view list of users who opened mobile app today">
                        <div style="display:flex; justify-content:space-between; align-items:center;">
                            <div class="metric-title"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="display:inline-block; vertical-align:-2px; margin-right:4px;"><rect x="5" y="2" width="14" height="20" rx="2" ry="2"/><line x1="12" y1="18" x2="12.01" y2="18"/></svg> App Opens Today</div>
                            <span style="font-size:11px; background:#d1fae5; color:#065f46; padding:2px 8px; border-radius:12px; font-weight:600;">View Users →</span>
                        </div>
                        <div class="metric-value" style="color:#059669;">${m.usage.today_app_opens || 0} Users</div>
                        <div class="metric-sub">Opened mobile app today — click to view list</div>
                    </div>
                    <div class="metric-card" style="border-left:4px solid #8b5cf6; cursor:pointer; transition:all 0.2s; position:relative;" onclick="switchNav('used-mobiles')" title="Click to view shops using Used Mobile Buy & Sell feature">
                        <div style="display:flex; justify-content:space-between; align-items:center;">
                            <div class="metric-title"><span style="font-size:14px; margin-right:4px;">📱</span> Used Mobiles Feature</div>
                            <span style="font-size:11px; background:#ede9fe; color:#6d28d9; padding:2px 8px; border-radius:12px; font-weight:600;">${m.used_mobiles ? m.used_mobiles.shops_count : 0} Shops Using →</span>
                        </div>
                        <div class="metric-value" style="color:#7c3aed;">${m.used_mobiles ? m.used_mobiles.total_devices : 0} Devices</div>
                        <div class="metric-sub" style="color:#64748b;">${m.used_mobiles ? m.used_mobiles.in_stock : 0} In Stock | ${m.used_mobiles ? m.used_mobiles.sold : 0} Sold (${m.used_mobiles ? '₹' + Number(m.used_mobiles.total_profit).toLocaleString() + ' profit' : '₹0'})</div>
                    </div>
                </div>

                <div class="card-table">
                    <div class="table-toolbar">
                        <div style="font-weight:700; font-size:15px;">Recently Registered Shops</div>
                    </div>
                    <div class="table-responsive">
                    <table>
                        <thead>
                            <tr>
                                <th>Shop Name</th>
                                <th>Owner</th>
                                <th>Mobile</th>
                                <th>Registered</th>
                                <th>Status</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${m.recent_shops.map(s => `
                                <tr>
                                    <td><strong>${s.name}</strong></td>
                                    <td>${s.owner_name}</td>
                                    <td>${s.phone || s.mobile || (s.user ? (s.user.mobile || s.user.phone) : 'N/A')}</td>
                                    <td>${new Date(s.created_at).toLocaleDateString()}</td>
                                    <td><span class="badge ${s.status === 'active' ? 'badge-active' : 'badge-inactive'}">${s.status}</span></td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                    </div>
                </div>
            `;
        }

        // MODAL: USERS WHO OPENED MOBILE APP TODAY
        async function showAppOpensTodayModal() {
            openModal('📱 Mobile App Opens Today', `
                <div style="text-align:center; padding:32px 16px; color:#64748b;">
                    <div style="font-size:32px; margin-bottom:8px;">⏳</div>
                    <div>Loading users who opened the mobile app today...</div>
                </div>
            `);

            const data = await apiFetch('/dashboard/app-opens-today');
            if (!data || !data.success) {
                document.getElementById('modal-body').innerHTML = '<div style="color:#dc2626; padding:20px; text-align:center;">Failed to load today\'s active users.</div>';
                return;
            }

            const users = data.data || [];
            if (users.length === 0) {
                document.getElementById('modal-body').innerHTML = `
                    <div style="text-align:center; padding:32px 16px;">
                        <div style="font-size:40px; margin-bottom:8px;">📱</div>
                        <h4 style="font-size:15px; font-weight:700; color:#1e293b; margin-bottom:4px;">No App Opens Yet Today</h4>
                        <p style="font-size:13px; color:#64748b; margin-bottom:16px;">No users have launched or interacted with the mobile app today yet.</p>
                        <button class="btn-sm" onclick="closeModal(); switchNav('users');">Browse All Users</button>
                    </div>
                `;
                return;
            }

            const html = `
                <div style="font-size:13px;">
                    <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:14px; padding-bottom:10px; border-bottom:1px solid #e2e8f0;">
                        <div>
                            <span style="font-weight:700; font-size:14px; color:#0f172a;">${users.length} Active User${users.length === 1 ? '' : 's'} Today</span>
                            <div style="font-size:12px; color:#64748b;">Sorted by most recently active</div>
                        </div>
                        <button class="btn-sm" style="background:#2563eb; color:white; border:none; padding:6px 12px;" onclick="closeModal(); switchNav('users'); setTimeout(() => loadUsersView(1, '', '', 'today'), 60);">
                            Full Users Table →
                        </button>
                    </div>

                    <div style="max-height:420px; overflow-y:auto; display:flex; flex-direction:column; gap:10px; padding-right:4px;">
                        ${users.map(u => {
                            const openTime = u.last_app_opened_at ? new Date(u.last_app_opened_at) : null;
                            const timeStr = openTime ? openTime.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : 'Today';
                            const shopName = u.shop ? u.shop.name : (u.role === 'super_admin' || u.role === 'admin' ? 'Platform Administrator' : 'Independent Account');
                            const phone = u.mobile || u.phone || '';
                            return `
                                <div style="display:flex; justify-content:space-between; align-items:center; background:#f8fafc; border:1px solid #e2e8f0; border-radius:10px; padding:12px 14px;">
                                    <div style="flex:1; min-width:0;">
                                        <div style="font-weight:700; color:#0f172a; display:flex; align-items:center; gap:8px;">
                                            ${u.name}
                                            <span class="badge ${u.role === 'owner' ? 'badge-active' : 'badge-trial'}" style="font-size:10px; text-transform:uppercase;">${u.role}</span>
                                        </div>
                                        <div style="font-size:12px; color:#475569; margin-top:4px;">
                                            🏪 <strong>${shopName}</strong>
                                        </div>
                                        <div style="font-size:12px; color:#64748b; margin-top:2px;">
                                            ${phone ? `📞 <a href="tel:${phone}" style="color:#2563eb; text-decoration:none; font-weight:500;">${phone}</a>` : '<span style="color:#94a3b8;">No phone</span>'}
                                            ${u.email ? `<span style="margin-left:8px;">✉️ ${u.email}</span>` : ''}
                                        </div>
                                    </div>
                                    <div style="text-align:right; margin-left:14px; flex-shrink:0;">
                                        <span style="display:inline-block; background:#dcfce7; color:#15803d; font-size:11px; font-weight:600; padding:4px 10px; border-radius:14px; border:1px solid #bbf7d0;">
                                            🟢 ${timeStr}
                                        </span>
                                    </div>
                                </div>
                            `;
                        }).join('')}
                    </div>
                </div>
            `;
            document.getElementById('modal-body').innerHTML = html;
        }

        // 2. SHOPS VIEW
        async function loadShopsView(page = 1, search = '', status = '', subStatus = '') {
            const content = getContentContainer();
            const data = await apiFetch(`/shops?page=${page}&search=${encodeURIComponent(search)}&status=${status}&subscription_status=${subStatus}`);
            if (!data || !data.success) return;
            const pageData = data.data;
            const shops = pageData.data || [];

            content.innerHTML = `
                <div class="card-table">
                    <div class="table-toolbar">
                        <div style="display:flex; gap:12px; flex:1; min-width:260px; align-items:center;">
                            <div class="search-box" style="flex:1;">
                                <input type="text" id="shops-search-input" placeholder="Search shop name, owner, phone, email..." value="${search}" oninput="debounceSearch(() => loadShopsView(1, document.getElementById('shops-search-input').value, '${status}', '${subStatus}'))">
                            </div>
                            <span style="font-size:12px; color:#64748b; font-weight:600; background:#f1f5f9; padding:6px 12px; border-radius:20px; white-space:nowrap; border:1px solid #e2e8f0;">
                                Total: ${pageData.total !== undefined ? pageData.total : shops.length} Shops
                            </span>
                        </div>
                        <div style="display:flex; gap:10px; flex-wrap:wrap; align-items:center;">
                            <button class="action-btn action-btn-indigo" onclick="openBulkDiscountModal()" style="padding:7px 13px; font-size:12px; box-shadow:0 1px 2px rgba(0,0,0,0.05);" title="Apply Discount Across ALL Shops">
                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><path d="m4.93 4.93 14.14 14.14"/></svg>
                                🏷️ Discount All Shops
                            </button>
                            <select class="filter-select" onchange="loadShopsView(1, '${search}', this.value, '${subStatus}')">
                                <option value="">Account: All Statuses</option>
                                <option value="active" ${status === 'active' ? 'selected' : ''}>Active Account</option>
                                <option value="deactivated" ${status === 'deactivated' ? 'selected' : ''}>Deactivated Account</option>
                            </select>
                            <select class="filter-select" onchange="loadShopsView(1, '${search}', '${status}', this.value)">
                                <option value="">Plan: All Subscriptions</option>
                                <option value="active" ${subStatus === 'active' ? 'selected' : ''}>Active Plan</option>
                                <option value="trial" ${subStatus === 'trial' ? 'selected' : ''}>Trial</option>
                                <option value="expired" ${subStatus === 'expired' ? 'selected' : ''}>Expired</option>
                            </select>
                            ${(search || status || subStatus) ? `<button class="btn-sm" style="background:#f1f5f9; color:#475569; border-color:#cbd5e1;" onclick="loadShopsView(1, '', '', '')">✕ Clear Filters</button>` : ''}
                        </div>
                    </div>
                    <div class="table-responsive">
                    <table>
                        <thead>
                            <tr>
                                <th>Shop & ID</th>
                                <th>Owner Name</th>
                                <th>Contact Number</th>
                                <th>Registration Date</th>
                                <th>Subscription</th>
                                <th>Staff Logins</th>
                                <th>Technicians</th>
                                <th>Account Status</th>
                                <th style="text-align:right;">Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${shops.length === 0 ? `<tr><td colspan="9" style="text-align:center; padding:36px; color:#94a3b8; font-weight:500;">No shops found matching filter criteria.</td></tr>` : ''}
                            ${shops.map(s => {
                                const mob = s.phone || s.mobile || (s.user ? (s.user.mobile || s.user.phone) : 'N/A');
                                const sub = s.latest_subscription ? s.latest_subscription.status : 'trial';
                                const initial = (s.name || 'S').trim().charAt(0).toUpperCase();
                                return `
                                <tr>
                                    <td>
                                        <div style="display:flex; align-items:center; gap:10px;">
                                            <div style="width:36px; height:36px; border-radius:9px; background:#eff6ff; border:1px solid #bfdbfe; color:#2563eb; display:flex; align-items:center; justify-content:center; font-weight:700; font-size:14px; flex-shrink:0;">
                                                ${initial}
                                            </div>
                                            <div>
                                                <div style="font-weight:700; color:#0f172a; font-size:13.5px;">${s.name}</div>
                                                <div style="font-size:11px; color:#64748b; font-family:monospace;">ID: #${s.id}</div>
                                            </div>
                                        </div>
                                    </td>
                                    <td>
                                        <div style="font-weight:600; color:#334155;">${s.owner_name}</div>
                                    </td>
                                    <td>
                                        <div style="font-family:monospace; font-size:13px; color:#475569;">${mob}</div>
                                    </td>
                                    <td>
                                        <div style="font-size:12.5px; color:#64748b;">${new Date(s.created_at).toLocaleDateString()}</div>
                                    </td>
                                    <td>
                                        <div style="display:flex; flex-direction:column; gap:4px; align-items:flex-start;">
                                            <span class="badge ${sub === 'active' ? 'badge-active' : (sub === 'expired' ? 'badge-inactive' : 'badge-trial')}">
                                                ${sub.toUpperCase()}
                                            </span>
                                            ${(s.custom_discount_percent > 0 || (s.custom_plan_prices && Object.keys(s.custom_plan_prices).length > 0))
                                                ? `<span class="badge badge-emerald" style="font-size:10px; padding:2px 6px;">
                                                       🏷️ ${s.custom_discount_percent ? s.custom_discount_percent + '% OFF' : 'Custom Pricing'}
                                                       ${s.custom_discount_is_one_time ? '<span style="opacity:0.85; margin-left:2px; font-weight:700;">(1-Time)</span>' : ''}
                                                   </span>`
                                                : (s.custom_discount_note && s.custom_discount_note.includes('consumed')
                                                    ? `<span class="badge" style="background:#f1f5f9; color:#64748b; font-size:9.5px; padding:2px 6px; border:1px solid #cbd5e1;">✅ 1-Time Used</span>`
                                                    : '')
                                            }
                                        </div>
                                    </td>
                                    <td>
                                        <div style="display:flex; flex-direction:column; gap:4px;">
                                            <div style="display:flex; align-items:center; gap:5px; flex-wrap:wrap;">
                                                <button type="button" class="badge ${s.staff_logins_count > 0 ? 'badge-blue' : 'badge-trial'}" 
                                                        style="cursor:pointer; border:1px dashed #6366f1; padding:4px 9px; display:inline-flex; align-items:center; gap:5px; font-weight:700;"
                                                        onclick="openCustomStaffModal(${s.id}, '${s.name.replace(/'/g, "\\'")}', ${s.effective_max_staff || 0}, ${s.custom_max_staff !== null && s.custom_max_staff !== undefined ? s.custom_max_staff : "''"}, '${s.custom_staff_valid_until || ''}', '${(s.custom_staff_note || '').replace(/'/g, "\\'")}', '${s.latest_subscription ? (s.latest_subscription.expiry_date || '') : ''}', '${s.latest_subscription ? s.latest_subscription.status : 'trial'}')"
                                                        title="Click to Increase or Change Staff Logins Limit">
                                                    👥 ${s.staff_logins_count || 0} / ${s.effective_max_staff || 0} Logins
                                                    <span style="font-size:10px; opacity:0.8;">✏️</span>
                                                </button>
                                            </div>
                                            ${s.custom_staff_valid_until ? (new Date(s.custom_staff_valid_until) < new Date() ? '<span class="badge badge-inactive" style="font-size:10px; padding:2px 6px;">🔴 Expired</span>' : `<span class="badge badge-purple" style="font-size:10px; padding:2px 6px;">⏱️ Till ${new Date(s.custom_staff_valid_until).toLocaleDateString()}</span>`) : ''}
                                        </div>
                                    </td>
                                    <td>
                                        <span class="badge" style="background:#f8fafc; color:#475569; font-weight:600; border:1px solid #cbd5e1; padding:4px 9px; display:inline-flex; align-items:center; gap:5px;" title="Repair technicians in shop directory (No Login)">
                                            🧰 ${s.technicians_count || 0} Techs
                                        </span>
                                    </td>
                                    <td>
                                        <span class="badge ${s.status === 'active' ? 'badge-active' : 'badge-inactive'}">
                                            ${s.status.toUpperCase()}
                                        </span>
                                    </td>
                                    <td style="text-align:right;">
                                        <div class="action-btn-group" style="justify-content:flex-end;">
                                            <button class="action-btn action-btn-default" onclick="openShopDetails(${s.id})" title="View Details">
                                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7Z"/><circle cx="12" cy="12" r="3"/></svg>
                                                Details
                                            </button>
                                            <button class="action-btn action-btn-emerald" onclick="openCustomPricingModal(${s.id}, '${s.name.replace(/'/g, "\\'")}')" title="Custom Pricing & Discounts">
                                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><path d="M16 8h-6a2 2 0 1 0 0 4h4a2 2 0 1 1 0 4H8"/><path d="M12 6v12"/></svg>
                                                Pricing
                                            </button>
                                            <button class="action-btn action-btn-indigo" onclick="openCustomStaffModal(${s.id}, '${s.name.replace(/'/g, "\\'")}', ${s.effective_max_staff || 0}, ${s.custom_max_staff !== null && s.custom_max_staff !== undefined ? s.custom_max_staff : "''"}, '${s.custom_staff_valid_until || ''}', '${(s.custom_staff_note || '').replace(/'/g, "\\'")}', '${s.latest_subscription ? (s.latest_subscription.expiry_date || '') : ''}', '${s.latest_subscription ? s.latest_subscription.status : 'trial'}')" title="Increase or Set Staff Logins Limit">
                                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
                                                Staff Limit
                                            </button>
                                            <button class="action-btn ${s.status === 'active' ? 'action-btn-danger' : 'action-btn-success'}" onclick="toggleShopStatus(${s.id}, '${s.status === 'active' ? 'deactivated' : 'active'}')" title="${s.status === 'active' ? 'Deactivate Shop' : 'Activate Shop'}">
                                                ${s.status === 'active' ? 'Deactivate' : 'Activate'}
                                            </button>
                                        </div>
                                    </td>
                                </tr>
                                `;
                            }).join('')}
                        </tbody>
                    </table>
                    </div>
                    ${renderPagination(pageData, 'loadShopsView', search, status, subStatus)}
                </div>
            `;
        }

        let _cachedShopsList = null;
        async function getShopsDropdownOptions(selectedId = '') {
            if (!_cachedShopsList) {
                const res = await apiFetch('/shops?per_page=100');
                if (res && res.success && res.data) {
                    _cachedShopsList = res.data.data || [];
                } else {
                    _cachedShopsList = [];
                }
            }
            let html = '<option value="">All Shops</option>';
            _cachedShopsList.forEach(s => {
                const sel = String(s.id) === String(selectedId) ? 'selected' : '';
                html += `<option value="${s.id}" ${sel}>${s.name}</option>`;
            });
            return html;
        }

        async function openShopDetails(id) {
            const data = await apiFetch(`/shops/${id}`);
            if (!data.success) return;
            const s = data.data;

            const mob = s.contact_mobile || s.phone || s.mobile || (s.user ? (s.user.mobile || s.user.phone) : 'N/A');
            const email = s.contact_email || s.email || (s.user ? s.user.email : 'N/A');

            openModal(`Shop Details — ${s.name}`, `
                <div style="font-size:13px; line-height:1.5;">
                    <div style="display:flex; gap:8px; border-bottom:1px solid #e2e8f0; margin-bottom:16px; padding-bottom:10px; overflow-x:auto;">
                        <button id="shop-tab-btn-overview" class="btn-sm" style="background:#2563eb; color:white; border-color:#2563eb;" onclick="switchShopTab('overview')">📋 Overview</button>
                        <button id="shop-tab-btn-staff" class="btn-sm" onclick="switchShopTab('staff')">👥 Staff Members (${(s.staff || []).length})</button>
                        <button id="shop-tab-btn-technicians" class="btn-sm" onclick="switchShopTab('technicians')">🧰 Technicians (${(s.technicians || []).length})</button>
                        <button id="shop-tab-btn-sales" class="btn-sm" onclick="switchShopTab('sales')">🛒 Sales (${s.sales_count})</button>
                        <button id="shop-tab-btn-repairs" class="btn-sm" onclick="switchShopTab('repairs')">🔧 Repairs (${s.repairs_count})</button>
                        <button id="shop-tab-btn-customers" class="btn-sm" onclick="switchShopTab('customers')">👥 Customers (${s.customers_count})</button>
                        <button id="shop-tab-btn-inventory" class="btn-sm" onclick="switchShopTab('inventory')">📦 Stock (${s.inventory_items_count})</button>
                    </div>

                    <div id="shop-tab-overview">
                        <p><strong>Shop Name:</strong> ${s.name}</p>
                        <p><strong>Owner:</strong> ${s.owner_name}</p>
                        <p><strong>Contact Mobile:</strong> ${mob} | <strong>Email:</strong> ${email}</p>
                        <p><strong>Registration Date:</strong> ${new Date(s.created_at).toLocaleString()}</p>
                        <p><strong>Account Status:</strong> <span class="badge ${s.status === 'active' ? 'badge-active' : 'badge-inactive'}">${s.status}</span></p>
                        <div style="background:#f1f5f9; padding:12px 14px; border-radius:8px; margin:12px 0; border:1px solid #cbd5e1;">
                            <div style="display:flex; justify-content:space-between; align-items:flex-start; gap:10px; flex-wrap:wrap;">
                                <div style="flex:1; min-width:240px;">
                                    <h4 style="margin:0 0 4px 0; font-size:13px; color:#1e293b; display:flex; align-items:center; gap:6px;">
                                        <span>👥</span> Staff App Logins Limit
                                    </h4>
                                    <div style="font-size:12px; color:#475569; line-height:1.6;">
                                        <div><strong>Effective Allowed:</strong> <span class="badge badge-active">${s.effective_max_staff || 0} Staff Logins</span></div>
                                        <div><strong>Base Plan Limit:</strong> ${s.latest_subscription && s.latest_subscription.plan ? s.latest_subscription.plan.max_staff_accounts : 0} Staff</div>
                                        <div><strong>Shop Custom Override:</strong> ${s.custom_max_staff !== null && s.custom_max_staff !== undefined ? `<strong style="color:#2563eb;">${s.custom_max_staff} Staff</strong> (Valid until: ${s.custom_staff_valid_until || 'Indefinite'}${s.custom_staff_note ? ' — Note: ' + s.custom_staff_note : ''})` : '<span style="color:#64748b;">None (Follows subscription plan)</span>'}</div>
                                    </div>
                                </div>
                                <button type="button" class="btn-sm" style="background:#4f46e5; color:white; border-color:#4f46e5; padding:6px 14px; font-weight:600;" onclick="openCustomStaffModal(${s.id}, '${s.name.replace(/'/g, "\\'")}', ${s.effective_max_staff || 0}, ${s.custom_max_staff !== null && s.custom_max_staff !== undefined ? s.custom_max_staff : "''"}, '${s.custom_staff_valid_until || ''}', '${(s.custom_staff_note || '').replace(/'/g, "\\'")}', '${s.latest_subscription ? (s.latest_subscription.expiry_date || '') : ''}', '${s.latest_subscription ? s.latest_subscription.status : 'trial'}')">
                                    ⚙️ Set Staff Limit
                                </button>
                            </div>
                        </div>

                        <div style="background:#ecfdf5; padding:12px 14px; border-radius:8px; margin:12px 0; border:1px solid #a7f3d0;">
                            <div style="display:flex; justify-content:space-between; align-items:flex-start; gap:10px; flex-wrap:wrap;">
                                <div style="flex:1; min-width:240px;">
                                    <h4 style="margin:0 0 4px 0; font-size:13px; color:#065f46; display:flex; align-items:center; gap:6px;">
                                        <span>💰</span> Custom Shop Pricing & Discounts
                                    </h4>
                                    <div style="font-size:12px; color:#047857; line-height:1.6;">
                                        <div><strong>General Discount:</strong> ${s.custom_discount_percent ? `<span class="badge badge-active" style="background:#059669;">${s.custom_discount_percent}% OFF</span>` : '<span style="color:#64748b;">No general discount</span>'}</div>
                                        <div><strong>Custom Plan Prices:</strong> ${s.custom_plan_prices && Object.keys(s.custom_plan_prices).length > 0 ? `<strong style="color:#047857;">${Object.keys(s.custom_plan_prices).length} plans overridden</strong>` : '<span style="color:#64748b;">Standard plan prices</span>'}</div>
                                        <div><strong>Staff Add-on Rate:</strong> ${s.custom_staff_price_per_day !== null && s.custom_staff_price_per_day !== undefined ? `<strong>₹${parseFloat(s.custom_staff_price_per_day).toFixed(2)} / day</strong>` : 'Default (₹2.00 / day)'}</div>
                                        <div><strong>Valid Until:</strong> ${s.custom_discount_valid_until || 'Indefinite'}${s.custom_discount_note ? ' — Note: ' + s.custom_discount_note : ''}</div>
                                    </div>
                                </div>
                                <button type="button" class="btn-sm" style="background:#059669; color:white; border-color:#059669; padding:6px 14px; font-weight:600;" onclick="openCustomPricingModal(${s.id}, '${s.name.replace(/'/g, "\\'")}')">
                                    ⚙️ Manage Shop Pricing
                                </button>
                            </div>
                        </div>

                        <div style="background:#eef2ff; padding:12px 14px; border-radius:8px; margin:12px 0; border:1px solid #c7d2fe;">
                            <div style="display:flex; justify-content:space-between; align-items:flex-start; gap:10px; flex-wrap:wrap;">
                                <div style="flex:1; min-width:240px;">
                                    <h4 style="margin:0 0 4px 0; font-size:13px; color:#3730a3; display:flex; align-items:center; gap:6px;">
                                        <span>🎁</span> Referral & Points (Shop-Wise)
                                    </h4>
                                    <div style="font-size:12px; color:#3730a3; line-height:1.7;">
                                        <div><strong>Referral Code:</strong> <code style="background:#e0e7ff; color:#312e81; padding:2px 6px; border-radius:4px; font-weight:700;">${s.referral_code || 'N/A'}</code> &bull; <strong>Points Balance:</strong> <span class="badge" style="background:#4f46e5; color:#ffffff; font-weight:700;">${parseFloat(s.referral_points_balance || 0).toFixed(2)} pts (₹${parseFloat(s.referral_points_balance || 0).toFixed(2)})</span></div>
                                        <div><strong>Active Rules:</strong> ${s.referral_enabled_override === true || s.referral_enabled_override === 1 ? 'Force Enabled for this shop' : (s.referral_enabled_override === false || s.referral_enabled_override === 0 ? 'Force Disabled (Hidden in app)' : 'Following Common Settings')}${s.referral_reward_mode_override ? ` &bull; Mode: <strong>${s.referral_reward_mode_override === 'recharge_only' ? 'Paid Recharge % Only' : 'Signup Points + Recharge %'}</strong>` : ''}</div>
                                    </div>
                                </div>
                                <button type="button" class="btn-sm" style="background:#4f46e5; color:white; border-color:#4f46e5; padding:6px 14px; font-weight:600;" onclick="openShopReferralModal(${s.id}, '${s.name.replace(/'/g, "\\'")}')">
                                    🎁 Manage Referral & Points
                                </button>
                            </div>
                        </div>
                        <hr style="margin:12px 0; border:0; border-top:1px solid #e2e8f0;">
                        <h4 style="font-size:12px; text-transform:uppercase; color:#64748b; margin-bottom:8px;">Platform Usage Totals</h4>
                        <div style="display:grid; grid-template-columns:1fr 1fr; gap:8px;">
                            <div style="background:#f8fafc; padding:8px; border-radius:6px;"><strong>Customers Logged:</strong> ${s.customers_count}</div>
                            <div style="background:#f8fafc; padding:8px; border-radius:6px;"><strong>Repairs Logged:</strong> ${s.repairs_count}</div>
                            <div style="background:#f8fafc; padding:8px; border-radius:6px;"><strong>Sales Invoices:</strong> ${s.sales_count}</div>
                            <div style="background:#f8fafc; padding:8px; border-radius:6px;"><strong>Devices Logged:</strong> ${s.devices_count}</div>
                            <div style="background:#f8fafc; padding:8px; border-radius:6px; grid-column:span 2;"><strong>Stock Items:</strong> ${s.inventory_items_count}</div>
                        </div>
                    </div>

                    <div id="shop-tab-staff" style="display:none;">
                        <div style="background:#f8fafc; border:1px solid #e2e8f0; border-radius:8px; padding:12px 16px; margin-bottom:14px; display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:10px;">
                            <div>
                                <div style="font-weight:700; color:#0f172a; font-size:13.5px; display:flex; align-items:center; gap:6px;">
                                    <span>👥</span> Staff App Logins & Permissions
                                </div>
                                <div style="font-size:12px; color:#64748b; margin-top:3px; display:flex; flex-wrap:wrap; align-items:center; gap:6px;">
                                    <span>Allowed Quota: <strong style="color:#0f172a;">${s.effective_max_staff || 0} Logins</strong></span> &bull; 
                                    <span>Active Staff Logins: <strong style="color:#2563eb;">${(s.staff || []).filter(x => x.is_active).length}</strong></span> &bull; 
                                    <span>Total Staff: <strong style="color:#0f172a;">${(s.staff || []).length}</strong></span>
                                    ${(s.staff || []).filter(x => x.is_active).length >= (s.effective_max_staff || 0) && (s.effective_max_staff || 0) > 0 ? '<span class="badge badge-inactive">Quota Full</span>' : ''}
                                    ${s.custom_staff_valid_until ? (new Date(s.custom_staff_valid_until) < new Date() ? '<span class="badge" style="background:#fee2e2; color:#b91c1c; font-weight:700;">🔴 Staff Expired</span>' : `<span class="badge" style="background:#e0e7ff; color:#3730a3; font-weight:700;">⏱️ Valid until ${new Date(s.custom_staff_valid_until).toLocaleDateString()}</span>`) : ''}
                                </div>
                            </div>
                            <div style="display:flex; gap:8px;">
                                <button type="button" class="btn-sm" style="background:#10b981; color:white; border-color:#10b981; padding:6px 14px; font-weight:600;" onclick="openAdminAddStaffModal(${s.id}, '${s.name ? s.name.replace(/'/g, "\\'") : ''}')">
                                    ➕ Add Staff Member
                                </button>
                                <button type="button" class="btn-sm" style="background:#4f46e5; color:white; border-color:#4f46e5; padding:6px 14px; font-weight:600;" onclick="openCustomStaffModal(${s.id}, '${s.name ? s.name.replace(/'/g, "\\'") : ''}', ${s.effective_max_staff || 0}, ${s.custom_max_staff !== null && s.custom_max_staff !== undefined ? s.custom_max_staff : "''"}, '${s.custom_staff_valid_until || ''}', '${s.custom_staff_note ? s.custom_staff_note.replace(/'/g, "\\'") : ''}', '${s.latest_subscription ? (s.latest_subscription.expiry_date || '') : ''}', '${s.latest_subscription ? s.latest_subscription.status : 'trial'}')">
                                    ⚙️ Adjust Staff Limit
                                </button>
                            </div>
                        </div>

                        ${(s.staff || []).length === 0 ? `
                            <div style="text-align:center; padding:32px 16px; color:#94a3b8; border:1px dashed #cbd5e1; border-radius:8px; background:#fafafa;">
                                <div style="font-size:32px; margin-bottom:6px;">👥</div>
                                <div style="font-weight:600; color:#475569; font-size:14px;">No Staff Accounts Added</div>
                                <div style="font-size:12px; color:#94a3b8; margin-top:2px;">This shop owner has not created any staff logins yet.</div>
                                <div style="margin-top:12px;">
                                    <button type="button" class="btn-sm" style="background:#10b981; color:white; border-color:#10b981; padding:6px 14px; font-weight:600;" onclick="openAdminAddStaffModal(${s.id}, '${s.name ? s.name.replace(/'/g, "\\'") : ''}')">
                                        ➕ Add First Staff Member
                                    </button>
                                </div>
                            </div>
                        ` : `
                            <div style="overflow-x:auto; border:1px solid #e2e8f0; border-radius:8px;">
                                <table style="width:100%; border-collapse:collapse; font-size:12px; text-align:left;">
                                    <thead>
                                        <tr style="background:#f8fafc; border-bottom:1px solid #e2e8f0; color:#475569; font-size:11px; text-transform:uppercase; letter-spacing:0.5px;">
                                            <th style="padding:10px 12px; white-space:nowrap;">Staff Name & Role</th>
                                            <th style="padding:10px 12px; white-space:nowrap;">Mobile (Login ID)</th>
                                            <th style="padding:10px 12px; white-space:nowrap;">Plain Password</th>
                                            <th style="padding:10px 12px; min-width:140px;">Module Permissions</th>
                                            <th style="padding:10px 12px; white-space:nowrap;">Salary / Joining</th>
                                            <th style="padding:10px 12px; text-align:center; white-space:nowrap;">Status</th>
                                            <th style="padding:10px 12px; text-align:right; white-space:nowrap;">Actions</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        ${(s.staff || []).map((st) => {
                                            const p = st.permissions || {};
                                            const permBadges = [];
                                            if (p.sales) permBadges.push('<span class="badge" style="background:#dbeafe; color:#1e40af; font-size:10px; padding:2px 6px;">🛒 Sales</span>');
                                            if (p.repairs) permBadges.push('<span class="badge" style="background:#fef3c7; color:#92400e; font-size:10px; padding:2px 6px;">🔧 Repairs</span>');
                                            if (p.stock || p.purchases) permBadges.push('<span class="badge" style="background:#e0e7ff; color:#3730a3; font-size:10px; padding:2px 6px;">📦 Stock</span>');
                                            if (p.expenses) permBadges.push('<span class="badge" style="background:#fce7f3; color:#9d174d; font-size:10px; padding:2px 6px;">💸 Expenses</span>');
                                            if (p.used_mobiles) permBadges.push('<span class="badge" style="background:#dcfce7; color:#166534; font-size:10px; padding:2px 6px;">📱 Used</span>');
                                            if (p.customers) permBadges.push('<span class="badge" style="background:#f3e8ff; color:#6b21a8; font-size:10px; padding:2px 6px;">👥 Customers</span>');

                                            return `
                                            <tr style="border-bottom:1px solid #f1f5f9; transition:background 0.15s;" onmouseover="this.style.background='#f8fafc'" onmouseout="this.style.background='transparent'">
                                                <td style="padding:10px 12px; vertical-align:top;">
                                                    <strong style="color:#0f172a; font-size:13px;">${st.name}</strong>
                                                    <div style="color:#64748b; font-size:11px; margin-top:2px;">💼 ${st.designation || 'Staff'}</div>
                                                    <div style="color:#94a3b8; font-size:10.5px; margin-top:3px;">Added: ${st.created_at ? new Date(st.created_at).toLocaleDateString() : 'N/A'}</div>
                                                </td>
                                                <td style="padding:10px 12px; vertical-align:top; white-space:nowrap;">
                                                    <a href="tel:${st.mobile}" style="color:#2563eb; text-decoration:none; font-weight:600;">📱 ${st.mobile || '—'}</a>
                                                    ${st.email ? `<div style="font-size:11px; color:#64748b; margin-top:2px;">✉️ ${st.email}</div>` : ''}
                                                </td>
                                                <td style="padding:10px 12px; vertical-align:top; white-space:nowrap;">
                                                    ${st.plain_password ? `
                                                        <span style="font-family:monospace; background:#e0e7ff; color:#3730a3; padding:3px 8px; border:1px solid #c7d2fe; border-radius:4px; font-weight:700; font-size:12px; letter-spacing:0.5px;">${st.plain_password}</span>
                                                    ` : '<span style="color:#94a3b8; font-size:12px;">••••••••</span>'}
                                                </td>
                                                <td style="padding:10px 12px; vertical-align:top;">
                                                    ${permBadges.length > 0 ? permBadges.join(' ') : '<span style="color:#94a3b8; font-size:11px;">Default</span>'}
                                                </td>
                                                <td style="padding:10px 12px; vertical-align:top; white-space:nowrap;">
                                                    ${st.salary ? `<div><strong>₹${parseFloat(st.salary).toFixed(2)}</strong> <span style="font-size:10.5px; color:#64748b;">/${st.salary_type || 'mo'}</span></div>` : '<div style="color:#94a3b8;">No salary set</div>'}
                                                    ${st.joining_date ? `<div style="font-size:11px; color:#64748b; margin-top:2px;">Joined: ${st.joining_date}</div>` : ''}
                                                </td>
                                                <td style="padding:10px 12px; vertical-align:top; text-align:center; white-space:nowrap;">
                                                    <button type="button" class="badge ${st.is_active ? 'badge-active' : 'badge-inactive'}" style="cursor:pointer; border:none; padding:3px 8px;" onclick="adminToggleStaffStatus(${s.id}, ${st.id})" title="Click to ${st.is_active ? 'Block Login' : 'Activate Login'}">
                                                        ${st.is_active ? '🟢 Active' : '🔴 Inactive'}
                                                    </button>
                                                </td>
                                                <td style="padding:10px 12px; vertical-align:top; text-align:right; white-space:nowrap;">
                                                    <button type="button" class="btn-sm" style="padding:3px 8px; font-size:11px; margin-right:4px;" onclick='openAdminEditStaffModal(${s.id}, ${JSON.stringify(st).replace(/'/g, "&#39;")})' title="Edit Staff Details">
                                                        ✏️ Edit
                                                    </button>
                                                    <button type="button" class="btn-sm" style="background:#fee2e2; color:#b91c1c; border-color:#fca5a5; padding:3px 8px; font-size:11px;" onclick="adminDeleteStaff(${s.id}, ${st.id}, '${st.name ? st.name.replace(/'/g, "\\'") : 'Staff'}')" title="Delete Staff Member">
                                                        🗑️
                                                    </button>
                                                </td>
                                            </tr>
                                            `;
                                        }).join('')}
                                    </tbody>
                                </table>
                            </div>
                        `}
                    </div>

                    <div id="shop-tab-technicians" style="display:none;">
                        <div style="background:#f8fafc; border:1px solid #e2e8f0; border-radius:8px; padding:12px 16px; margin-bottom:14px; display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:10px;">
                            <div>
                                <div style="font-weight:700; color:#0f172a; font-size:13.5px; display:flex; align-items:center; gap:6px;">
                                    <span>🧰</span> Repair Technicians (Shop Floor Specialists)
                                </div>
                                <div style="font-size:12px; color:#64748b; margin-top:3px;">
                                    <span>Total Technicians: <strong style="color:#0f172a;">${(s.technicians || []).length}</strong></span> &bull; 
                                    <span style="color:#059669; font-weight:600;">Unlimited & Free (For assigning repair tickets, earnings & payouts)</span>
                                </div>
                            </div>
                        </div>

                        ${(s.technicians || []).length === 0 ? `
                            <div style="text-align:center; padding:32px 16px; color:#94a3b8; border:1px dashed #cbd5e1; border-radius:8px; background:#fafafa;">
                                <div style="font-size:32px; margin-bottom:6px;">🧰</div>
                                <div style="font-weight:600; color:#475569; font-size:14px;">No Technicians Added</div>
                                <div style="font-size:12px; color:#94a3b8; margin-top:2px;">This shop owner has not added any technicians yet.</div>
                            </div>
                        ` : `
                            <div style="overflow-x:auto; border:1px solid #e2e8f0; border-radius:8px;">
                                <table style="width:100%; border-collapse:collapse; font-size:12px; text-align:left;">
                                    <thead>
                                        <tr style="background:#f8fafc; border-bottom:1px solid #e2e8f0; color:#475569; font-size:11px; text-transform:uppercase; letter-spacing:0.5px;">
                                            <th style="padding:10px 12px; white-space:nowrap;">Technician Name</th>
                                            <th style="padding:10px 12px; white-space:nowrap;">Contact Phone</th>
                                            <th style="padding:10px 12px; white-space:nowrap;">Specialization</th>
                                            <th style="padding:10px 12px; text-align:right; white-space:nowrap;">Repairs Count</th>
                                            <th style="padding:10px 12px; text-align:right; white-space:nowrap;">Total Earnings</th>
                                            <th style="padding:10px 12px; text-align:right; white-space:nowrap;">Total Paid</th>
                                            <th style="padding:10px 12px; text-align:center; white-space:nowrap;">Status</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        ${(s.technicians || []).map((t) => `
                                            <tr style="border-bottom:1px solid #f1f5f9; transition:background 0.15s;" onmouseover="this.style.background='#f8fafc'" onmouseout="this.style.background='transparent'">
                                                <td style="padding:10px 12px; vertical-align:top;">
                                                    <strong style="color:#0f172a; font-size:13px;">${t.name}</strong>
                                                    <div style="color:#94a3b8; font-size:10.5px; margin-top:3px;">Added: ${t.created_at ? new Date(t.created_at).toLocaleDateString() : 'N/A'}</div>
                                                </td>
                                                <td style="padding:10px 12px; vertical-align:top; white-space:nowrap;">
                                                    <a href="tel:${t.mobile}" style="color:#2563eb; text-decoration:none; font-weight:600;">📞 ${t.mobile || '—'}</a>
                                                </td>
                                                <td style="padding:10px 12px; vertical-align:top; white-space:nowrap;">
                                                    <span class="badge badge-purple" style="font-size:11px; padding:3px 8px;">🔧 ${t.specialization || 'General Repair'}</span>
                                                </td>
                                                <td style="padding:10px 12px; vertical-align:top; text-align:right; white-space:nowrap;">
                                                    <strong>${t.repairs_count || 0} jobs</strong>
                                                </td>
                                                <td style="padding:10px 12px; vertical-align:top; text-align:right; white-space:nowrap; color:#059669; font-weight:700;">
                                                    ₹${parseFloat(t.total_earnings || 0).toFixed(2)}
                                                </td>
                                                <td style="padding:10px 12px; vertical-align:top; text-align:right; white-space:nowrap; color:#2563eb; font-weight:600;">
                                                    ₹${parseFloat(t.total_paid || 0).toFixed(2)}
                                                </td>
                                                <td style="padding:10px 12px; vertical-align:top; text-align:center; white-space:nowrap;">
                                                    <span class="badge ${t.is_active ? 'badge-active' : 'badge-inactive'}">${t.is_active ? 'Active' : 'Inactive'}</span>
                                                </td>
                                            </tr>
                                        `).join('')}
                                    </tbody>
                                </table>
                            </div>
                        `}
                    </div>

                    <div id="shop-tab-sales" style="display:none;">
                        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:10px;">
                            <h4 style="font-size:14px; font-weight:700; color:#0f172a; margin:0;">Recent Sales Invoices</h4>
                            <span style="font-size:12px; color:#64748b;">Showing latest ${(s.recent_sales || []).length} of ${s.sales_count}</span>
                        </div>
                        ${(s.recent_sales || []).length === 0 ? '<p style="color:#94a3b8; padding:20px; text-align:center;">No sales logged yet for this shop.</p>' : `
                            <div style="overflow-x:auto; border:1px solid #e2e8f0; border-radius:8px;">
                                <table style="width:100%; border-collapse:collapse; font-size:12.5px; text-align:left;">
                                    <thead>
                                        <tr style="background:#f8fafc; border-bottom:1px solid #e2e8f0; color:#475569; font-size:11.5px; text-transform:uppercase; letter-spacing:0.5px;">
                                            <th style="padding:10px 12px; white-space:nowrap;">Invoice #</th>
                                            <th style="padding:10px 12px; white-space:nowrap;">Customer</th>
                                            <th style="padding:10px 12px; white-space:nowrap;">Date</th>
                                            <th style="padding:10px 12px; text-align:right; white-space:nowrap;">Total</th>
                                            <th style="padding:10px 12px; text-align:center; white-space:nowrap;">Status</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        ${s.recent_sales.map(rs => {
                                            const isPaid = (rs.payment_status || '').toLowerCase() === 'paid';
                                            const isPartial = (rs.payment_status || '').toLowerCase() === 'partial';
                                            const badgeCls = isPaid ? 'badge-active' : (isPartial ? 'badge-trial' : 'badge-inactive');
                                            return `
                                            <tr style="border-bottom:1px solid #f1f5f9; transition:background 0.15s;" onmouseover="this.style.background='#f8fafc'" onmouseout="this.style.background='transparent'">
                                                <td style="padding:10px 12px; white-space:nowrap;"><strong style="font-family:monospace; color:#0f172a;">${rs.invoice_number || 'INV-' + rs.id}</strong></td>
                                                <td style="padding:10px 12px; white-space:nowrap;">${rs.customer ? rs.customer.name : (rs.customer_name || 'Walk-in Customer')}</td>
                                                <td style="padding:10px 12px; white-space:nowrap; color:#64748b;">${new Date(rs.sale_date || rs.created_at).toLocaleDateString()}</td>
                                                <td style="padding:10px 12px; text-align:right; white-space:nowrap; font-weight:700; color:#0f172a;">₹${parseFloat(rs.grand_total).toFixed(2)}</td>
                                                <td style="padding:10px 12px; text-align:center; white-space:nowrap;"><span class="badge ${badgeCls}">${(rs.payment_status || '').toUpperCase()}</span></td>
                                            </tr>
                                            `;
                                        }).join('')}
                                    </tbody>
                                </table>
                            </div>
                        `}
                    </div>

                    <div id="shop-tab-repairs" style="display:none;">
                        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:10px;">
                            <h4 style="font-size:14px; font-weight:700; color:#0f172a; margin:0;">Recent Repair Jobs</h4>
                            <span style="font-size:12px; color:#64748b;">Showing latest ${(s.recent_repairs || []).length} of ${s.repairs_count}</span>
                        </div>
                        ${(s.recent_repairs || []).length === 0 ? '<p style="color:#94a3b8; padding:20px; text-align:center;">No repair jobs logged yet for this shop.</p>' : `
                            <div style="overflow-x:auto; border:1px solid #e2e8f0; border-radius:8px;">
                                <table style="width:100%; border-collapse:collapse; font-size:12.5px; text-align:left;">
                                    <thead>
                                        <tr style="background:#f8fafc; border-bottom:1px solid #e2e8f0; color:#475569; font-size:11.5px; text-transform:uppercase; letter-spacing:0.5px;">
                                            <th style="padding:10px 12px; white-space:nowrap;">Job #</th>
                                            <th style="padding:10px 12px; white-space:nowrap;">Customer & Contact</th>
                                            <th style="padding:10px 12px; white-space:nowrap;">Device</th>
                                            <th style="padding:10px 12px; min-width:180px;">Problem</th>
                                            <th style="padding:10px 12px; text-align:right; white-space:nowrap;">Cost</th>
                                            <th style="padding:10px 12px; text-align:center; white-space:nowrap;">Status</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        ${s.recent_repairs.map(rr => {
                                            const rcName = rr.customer ? rr.customer.name : (rr.customer_name || 'Walk-in Customer');
                                            const rcMobile = rr.customer ? (rr.customer.mobile || rr.customer.phone || '') : '';
                                            const rdInfo = rr.device ? `${rr.device.brand || ''} ${rr.device.model || ''}`.trim() : 'N/A';
                                            const costVal = parseFloat(rr.final_cost > 0 ? rr.final_cost : (rr.estimated_cost || 0)).toFixed(2);
                                            const statusLower = (rr.repair_status || '').toLowerCase();
                                            let badgeClass = 'badge-trial';
                                            if (['delivered', 'completed'].includes(statusLower)) badgeClass = 'badge-active';
                                            else if (['cancelled', 'unrepairable', 'cannot_repair'].includes(statusLower)) badgeClass = 'badge-inactive';
                                            else if (['ready'].includes(statusLower)) badgeClass = 'badge-blue';
                                            else if (['in_progress'].includes(statusLower)) badgeClass = 'badge-trial';

                                            return `
                                            <tr style="border-bottom:1px solid #f1f5f9; transition:background 0.15s;" onmouseover="this.style.background='#f8fafc'" onmouseout="this.style.background='transparent'">
                                                <td style="padding:10px 12px; white-space:nowrap; vertical-align:top;">
                                                    <strong style="color:#0f172a; font-family:monospace; font-size:12.5px;">${rr.job_number || 'JOB-' + rr.id}</strong>
                                                </td>
                                                <td style="padding:10px 12px; vertical-align:top; white-space:nowrap;">
                                                    <strong style="color:#0f172a;">${rcName}</strong>
                                                    ${rcMobile ? `<br><a href="tel:${rcMobile}" style="font-size:11px; color:#2563eb; text-decoration:none; display:inline-block; margin-top:2px;">📞 ${rcMobile}</a>` : ''}
                                                </td>
                                                <td style="padding:10px 12px; vertical-align:top; white-space:nowrap;">
                                                    <span style="color:#334155; font-weight:500;">📱 ${rdInfo}</span>
                                                </td>
                                                <td style="padding:10px 12px; vertical-align:top; color:#475569; line-height:1.4;">
                                                    ${rr.problem_description || '—'}
                                                </td>
                                                <td style="padding:10px 12px; vertical-align:top; text-align:right; white-space:nowrap; font-weight:700; color:#0f172a;">
                                                    ₹${costVal}
                                                </td>
                                                <td style="padding:10px 12px; vertical-align:top; text-align:center; white-space:nowrap;">
                                                    <span class="badge ${badgeClass}">${(rr.repair_status || '').toUpperCase()}</span>
                                                </td>
                                            </tr>
                                            `;
                                        }).join('')}
                                    </tbody>
                                </table>
                            </div>
                        `}
                    </div>

                    <div id="shop-tab-customers" style="display:none;">
                        <h4 style="font-size:13px; font-weight:700; margin-bottom:8px;">Recent Customers</h4>
                        ${(s.recent_customers || []).length === 0 ? '<p style="color:#94a3b8;">No customers registered for this shop.</p>' : `
                            <ul style="list-style:none; padding:0;">
                                ${s.recent_customers.map(rc => `
                                    <li style="padding:8px 12px; border-bottom:1px solid #e2e8f0; display:flex; justify-content:space-between; align-items:center;">
                                        <span><strong>${rc.name}</strong> (${rc.mobile})</span>
                                        <span style="color:#64748b; font-size:11px;">Added ${new Date(rc.created_at).toLocaleDateString()}</span>
                                    </li>
                                `).join('')}
                            </ul>
                        `}
                    </div>

                    <div id="shop-tab-inventory" style="display:none;">
                        <h4 style="font-size:13px; font-weight:700; margin-bottom:8px;">Recent Stock Items</h4>
                        ${(s.recent_inventory || []).length === 0 ? '<p style="color:#94a3b8;">No inventory items for this shop.</p>' : `
                            <table style="width:100%; border-collapse:collapse; font-size:12px;">
                                <thead>
                                    <tr style="background:#f8fafc;"><th>Item Name</th><th>SKU</th><th>Stock</th><th>Price</th></tr>
                                </thead>
                                <tbody>
                                    ${s.recent_inventory.map(ri => `
                                        <tr>
                                            <td style="padding:6px; border-bottom:1px solid #e2e8f0;">${ri.name}</td>
                                            <td style="padding:6px; border-bottom:1px solid #e2e8f0;">${ri.sku || '—'}</td>
                                            <td style="padding:6px; border-bottom:1px solid #e2e8f0;"><strong>${ri.current_stock}</strong></td>
                                            <td style="padding:6px; border-bottom:1px solid #e2e8f0;">₹${parseFloat(ri.selling_price).toFixed(2)}</td>
                                        </tr>
                                    `).join('')}
                                </tbody>
                            </table>
                        `}
                    </div>
                </div>
            `, '920px');
        }

        function switchShopTab(tab) {
            const tabs = ['overview', 'staff', 'technicians', 'sales', 'repairs', 'customers', 'inventory'];
            tabs.forEach(t => {
                const el = document.getElementById(`shop-tab-${t}`);
                if (el) el.style.display = t === tab ? 'block' : 'none';
                const btn = document.getElementById(`shop-tab-btn-${t}`);
                if (btn) {
                    if (t === tab) {
                        btn.style.background = '#2563eb';
                        btn.style.color = 'white';
                        btn.style.borderColor = '#2563eb';
                    } else {
                        btn.style.background = 'white';
                        btn.style.color = '#334155';
                        btn.style.borderColor = '#cbd5e1';
                    }
                }
            });
        }

        async function toggleShopStatus(id, newStatus) {
            if (!confirm(`Are you sure you want to change this shop status to ${newStatus}?`)) return;
            const data = await apiFetch(`/shops/${id}/toggle-status`, 'POST', { status: newStatus, reason: 'Admin panel toggle' });
            if (data.success) {
                alert(`Shop has been ${newStatus}.`);
                loadShopsView();
            }
        }

        function openCustomStaffModal(shopId, shopName, effectiveMax = 0, currentCustomMax = '', currentValidUntil = '', currentNote = '', subExpiry = '', subStatus = 'trial') {
            const hasCustom = (currentCustomMax !== '' && currentCustomMax !== null && currentCustomMax !== undefined);
            const currentVal = hasCustom ? currentCustomMax : effectiveMax;
            const expDateFormatted = subExpiry ? new Date(subExpiry).toISOString().split('T')[0] : '';

            openModal(`⚙️ Set Staff Logins Limit — ${shopName}`, `
                <form onsubmit="saveShopCustomStaff(event, ${shopId})">
                    <div style="background:#f8fafc; border:1px solid #e2e8f0; border-radius:10px; padding:12px 14px; margin-bottom:14px;">
                        <div style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:8px;">
                            <div>
                                <strong style="font-size:14px; color:#0f172a;">${shopName}</strong>
                                <span style="font-size:11px; color:#64748b; margin-left:4px;">(Shop #${shopId})</span>
                            </div>
                            <span class="badge ${subStatus === 'active' ? 'badge-active' : 'badge-trial'}">
                                ${subStatus.toUpperCase()}
                            </span>
                        </div>
                        <div style="font-size:12px; color:#475569; margin-top:6px; display:flex; flex-wrap:wrap; gap:12px; align-items:center;">
                            <div>Current Effective Limit: <strong style="color:#2563eb; font-size:13px;">${effectiveMax} Logins</strong></div>
                            <div>Status: <strong>${hasCustom ? `<span style="color:#7c3aed;">Custom Override (${currentCustomMax})</span>` : '<span style="color:#64748b;">Plan Default</span>'}</strong></div>
                            ${subExpiry ? `<div>Plan Expiry: <strong>${new Date(subExpiry).toLocaleDateString()}</strong></div>` : ''}
                        </div>
                    </div>

                    <div class="form-group" style="margin-bottom:14px;">
                        <label style="font-weight:700; color:#1e293b; display:flex; justify-content:space-between; align-items:center;">
                            <span>Total Allowed Staff App Logins</span>
                            <span style="font-size:11px; color:#64748b; font-weight:normal;">Technicians are unlimited & free</span>
                        </label>
                        
                        <!-- Quick Increment Buttons -->
                        <div style="display:flex; gap:6px; flex-wrap:wrap; margin:8px 0;">
                            <span style="font-size:11px; color:#64748b; align-self:center; margin-right:2px;">Quick Adjust:</span>
                            <button type="button" class="btn-sm" style="background:#eff6ff; color:#1d4ed8; border:1px solid #bfdbfe; font-weight:700;" onclick="incrementStaffMax(1)">+1 Staff</button>
                            <button type="button" class="btn-sm" style="background:#eff6ff; color:#1d4ed8; border:1px solid #bfdbfe; font-weight:700;" onclick="incrementStaffMax(2)">+2 Staff</button>
                            <button type="button" class="btn-sm" style="background:#eff6ff; color:#1d4ed8; border:1px solid #bfdbfe; font-weight:700;" onclick="incrementStaffMax(5)">+5 Staff</button>
                            <button type="button" class="btn-sm" style="background:#f1f5f9; color:#334155; border:1px solid #cbd5e1;" onclick="setStaffMaxVal(2)">Set 2</button>
                            <button type="button" class="btn-sm" style="background:#f1f5f9; color:#334155; border:1px solid #cbd5e1;" onclick="setStaffMaxVal(5)">Set 5</button>
                            <button type="button" class="btn-sm" style="background:#f1f5f9; color:#334155; border:1px solid #cbd5e1;" onclick="setStaffMaxVal(10)">Set 10</button>
                        </div>

                        <input type="number" id="shop-custom-staff-max" class="form-control" value="${currentVal}" placeholder="Enter staff logins limit (e.g. 2, 3, 5...)" min="0" max="100" style="font-size:15px; font-weight:700; padding:10px 12px;" required>
                        <small style="color:#64748b; font-size:11.5px; margin-top:3px; display:block;">Enter the new total number of staff members this shop is allowed to create app logins for.</small>
                    </div>

                    <div class="form-group" style="margin-bottom:14px;">
                        <label style="font-weight:700; color:#1e293b;">Valid Until Date (Override Expiry)</label>
                        
                        <!-- Quick Expiry Buttons -->
                        <div style="display:flex; gap:6px; flex-wrap:wrap; margin:6px 0;">
                            <span style="font-size:11px; color:#64748b; align-self:center; margin-right:2px;">Presets:</span>
                            ${expDateFormatted ? `<button type="button" class="btn-sm" style="background:#f0fdf4; color:#15803d; border:1px solid #bbf7d0; font-weight:600;" onclick="setStaffDateVal('${expDateFormatted}')">Match Plan Expiry</button>` : ''}
                            <button type="button" class="btn-sm" style="background:#f8fafc; color:#475569; border:1px solid #cbd5e1;" onclick="setStaffDateFromDays(30)">+30 Days</button>
                            <button type="button" class="btn-sm" style="background:#f8fafc; color:#475569; border:1px solid #cbd5e1;" onclick="setStaffDateFromDays(90)">+90 Days</button>
                            <button type="button" class="btn-sm" style="background:#f8fafc; color:#475569; border:1px solid #cbd5e1;" onclick="setStaffDateFromDays(365)">+1 Year</button>
                            <button type="button" class="btn-sm" style="background:#f8fafc; color:#475569; border:1px solid #cbd5e1;" onclick="setStaffDateVal('')">Indefinite (No Expiry)</button>
                        </div>

                        <input type="date" id="shop-custom-staff-date" class="form-control" value="${currentValidUntil || ''}">
                        <small style="color:#64748b; font-size:11.5px; margin-top:3px; display:block;">Optional. Leave blank for indefinite. When this date passes, staff limit automatically reverts to their plan limit!</small>
                    </div>

                    <div class="form-group" style="margin-bottom:18px;">
                        <label style="font-weight:700; color:#1e293b;">Admin Note / Reason</label>
                        <input type="text" id="shop-custom-staff-note" class="form-control" value="${currentNote || ''}" placeholder="e.g. Purchased 2 staff logins, Diwali promo, special request">
                    </div>

                    <div style="display:flex; gap:10px; flex-wrap:wrap; border-top:1px solid #e2e8f0; padding-top:14px;">
                        <button type="submit" class="btn-primary" style="flex:2; padding:10px 18px; font-weight:700;">💾 Save Staff Limit</button>
                        <button type="button" class="btn-sm" style="background:#fee2e2; color:#b91c1c; border-color:#fca5a5; padding:10px 14px;" onclick="clearShopCustomStaff(${shopId})" title="Revert to base subscription plan limit">🔄 Clear Override</button>
                        <button type="button" class="btn-sm" style="padding:10px 14px;" onclick="closeModal()">Cancel</button>
                    </div>
                </form>
            `);
        }

        function incrementStaffMax(delta) {
            const el = document.getElementById('shop-custom-staff-max');
            if (el) {
                const current = parseInt(el.value) || 0;
                el.value = Math.max(0, current + delta);
            }
        }

        function setStaffMaxVal(val) {
            const el = document.getElementById('shop-custom-staff-max');
            if (el) el.value = val;
        }

        function setStaffDateVal(dateStr) {
            const el = document.getElementById('shop-custom-staff-date');
            if (el) el.value = dateStr;
        }

        function setStaffDateFromDays(days) {
            const d = new Date();
            d.setDate(d.getDate() + days);
            setStaffDateVal(d.toISOString().split('T')[0]);
        }

        async function saveShopCustomStaff(e, shopId) {
            e.preventDefault();
            const maxVal = document.getElementById('shop-custom-staff-max').value.trim();
            const dateVal = document.getElementById('shop-custom-staff-date').value.trim();
            const noteVal = document.getElementById('shop-custom-staff-note').value.trim();

            const body = {
                custom_max_staff: maxVal !== '' ? parseInt(maxVal) : null,
                custom_staff_valid_until: dateVal !== '' ? dateVal : null,
                custom_staff_note: noteVal !== '' ? noteVal : null,
            };

            const res = await apiFetch(`/shops/${shopId}/staff-limit`, 'POST', body);
            if (res && res.success) {
                alert('Shop staff limit updated successfully!');
                closeModal();
                loadShopsView();
                // If shop details modal was also open, refresh it
                if (document.getElementById('shop-tab-overview')) {
                    openShopDetails(shopId);
                }
            } else {
                alert(res.message || 'Failed to update shop staff limit');
            }
        }

        async function clearShopCustomStaff(shopId) {
            if (!confirm('Clear custom staff override and revert this shop to their subscription plan limit?')) return;
            const res = await apiFetch(`/shops/${shopId}/staff-limit`, 'POST', {
                custom_max_staff: null,
                custom_staff_valid_until: null,
                custom_staff_note: null,
            });
            if (res && res.success) {
                alert('Custom override cleared. Shop will now follow their subscription plan limit.');
                closeModal();
                loadShopsView();
                if (document.getElementById('shop-tab-overview')) {
                    openShopDetails(shopId);
                }
            } else {
                alert(res.message || 'Failed to clear override');
            }
        }

        function openAdminAddStaffModal(shopId, shopName) {
            openModal(`➕ Add Staff Member — ${shopName}`, `
                <form onsubmit="saveAdminStaff(event, ${shopId})">
                    <div class="form-group" style="margin-bottom:12px;">
                        <label style="font-weight:600;">Full Name *</label>
                        <input type="text" id="admin-staff-name" class="form-control" required placeholder="e.g. Ramesh Kumar">
                    </div>
                    <div class="form-group" style="margin-bottom:12px;">
                        <label style="font-weight:600;">Mobile Number (App Login ID) *</label>
                        <input type="tel" id="admin-staff-mobile" class="form-control" required placeholder="10-digit mobile number" maxlength="10">
                    </div>
                    <div class="form-group" style="margin-bottom:12px;">
                        <label style="font-weight:600;">Login Password *</label>
                        <input type="text" id="admin-staff-password" class="form-control" required placeholder="At least 4 characters" minlength="4">
                    </div>
                    <div class="form-group" style="margin-bottom:12px;">
                        <label style="font-weight:600;">Designation / Role Title</label>
                        <input type="text" id="admin-staff-designation" class="form-control" placeholder="e.g. Sales Executive, Cashier, Manager" value="Sales Executive">
                    </div>
                    <div style="display:grid; grid-template-columns:1fr 1fr; gap:10px; margin-bottom:12px;">
                        <div class="form-group">
                            <label style="font-weight:600;">Salary (₹/mo)</label>
                            <input type="number" id="admin-staff-salary" class="form-control" placeholder="e.g. 15000">
                        </div>
                        <div class="form-group">
                            <label style="font-weight:600;">Joining Date</label>
                            <input type="date" id="admin-staff-joining" class="form-control">
                        </div>
                    </div>
                    <div class="form-group" style="margin-bottom:12px;">
                        <label style="font-weight:600;">Email (Optional)</label>
                        <input type="email" id="admin-staff-email" class="form-control" placeholder="staff@example.com">
                    </div>
                    <div class="form-group" style="margin-bottom:14px;">
                        <label style="font-weight:600;">Module Access Permissions</label>
                        <div style="display:grid; grid-template-columns:1fr 1fr; gap:8px; margin-top:4px; font-size:12px; background:#f8fafc; padding:10px; border-radius:8px; border:1px solid #e2e8f0;">
                            <label style="display:flex; align-items:center; gap:6px; cursor:pointer;"><input type="checkbox" id="admin-perm-sales" checked> 🛒 Sales</label>
                            <label style="display:flex; align-items:center; gap:6px; cursor:pointer;"><input type="checkbox" id="admin-perm-repairs" checked> 🔧 Repairs</label>
                            <label style="display:flex; align-items:center; gap:6px; cursor:pointer;"><input type="checkbox" id="admin-perm-stock"> 📦 Stock</label>
                            <label style="display:flex; align-items:center; gap:6px; cursor:pointer;"><input type="checkbox" id="admin-perm-expenses"> 💸 Expenses</label>
                            <label style="display:flex; align-items:center; gap:6px; cursor:pointer;"><input type="checkbox" id="admin-perm-used"> 📱 Used Mobiles</label>
                            <label style="display:flex; align-items:center; gap:6px; cursor:pointer;"><input type="checkbox" id="admin-perm-customers" checked> 👥 Customers</label>
                        </div>
                    </div>
                    <div style="display:flex; gap:10px; margin-top:16px;">
                        <button type="submit" class="btn-primary" style="flex:1;">Create Staff Member</button>
                        <button type="button" class="btn-sm" onclick="closeModal()">Cancel</button>
                    </div>
                </form>
            `);
        }

        async function saveAdminStaff(e, shopId) {
            e.preventDefault();
            const body = {
                name: document.getElementById('admin-staff-name').value.trim(),
                mobile: document.getElementById('admin-staff-mobile').value.trim(),
                password: document.getElementById('admin-staff-password').value.trim(),
                designation: document.getElementById('admin-staff-designation').value.trim(),
                salary: document.getElementById('admin-staff-salary').value ? parseFloat(document.getElementById('admin-staff-salary').value) : null,
                joining_date: document.getElementById('admin-staff-joining').value || null,
                email: document.getElementById('admin-staff-email').value.trim() || null,
                is_active: true,
                permissions: {
                    sales: document.getElementById('admin-perm-sales').checked,
                    repairs: document.getElementById('admin-perm-repairs').checked,
                    purchases: document.getElementById('admin-perm-stock').checked,
                    expenses: document.getElementById('admin-perm-expenses').checked,
                    used_mobiles: document.getElementById('admin-perm-used').checked,
                    customers: document.getElementById('admin-perm-customers').checked,
                }
            };

            const res = await apiFetch(`/shops/${shopId}/staff`, 'POST', body);
            if (res && res.success) {
                alert('Staff member created successfully!');
                closeModal();
                openShopDetails(shopId);
                loadShopsView();
            } else {
                alert(res.message || 'Failed to create staff member');
            }
        }

        function openAdminEditStaffModal(shopId, staff) {
            const p = staff.permissions || {};
            openModal(`✏️ Edit Staff — ${staff.name}`, `
                <form onsubmit="saveAdminEditStaff(event, ${shopId}, ${staff.id})">
                    <div class="form-group" style="margin-bottom:12px;">
                        <label style="font-weight:600;">Full Name *</label>
                        <input type="text" id="edit-staff-name" class="form-control" required value="${staff.name || ''}">
                    </div>
                    <div class="form-group" style="margin-bottom:12px;">
                        <label style="font-weight:600;">Mobile Number (App Login ID) *</label>
                        <input type="tel" id="edit-staff-mobile" class="form-control" required value="${staff.mobile || ''}" maxlength="10">
                    </div>
                    <div class="form-group" style="margin-bottom:12px;">
                        <label style="font-weight:600;">Change Password (Leave blank to keep)</label>
                        <input type="text" id="edit-staff-password" class="form-control" placeholder="Leave empty to keep current password" minlength="4">
                    </div>
                    <div class="form-group" style="margin-bottom:12px;">
                        <label style="font-weight:600;">Designation / Role Title</label>
                        <input type="text" id="edit-staff-designation" class="form-control" value="${staff.designation || 'Staff'}">
                    </div>
                    <div style="display:grid; grid-template-columns:1fr 1fr; gap:10px; margin-bottom:12px;">
                        <div class="form-group">
                            <label style="font-weight:600;">Salary (₹/mo)</label>
                            <input type="number" id="edit-staff-salary" class="form-control" value="${staff.salary !== null && staff.salary !== undefined ? staff.salary : ''}">
                        </div>
                        <div class="form-group">
                            <label style="font-weight:600;">Joining Date</label>
                            <input type="date" id="edit-staff-joining" class="form-control" value="${staff.joining_date || ''}">
                        </div>
                    </div>
                    <div class="form-group" style="margin-bottom:12px;">
                        <label style="font-weight:600;">Email (Optional)</label>
                        <input type="email" id="edit-staff-email" class="form-control" value="${staff.email || ''}">
                    </div>
                    <div class="form-group" style="margin-bottom:14px;">
                        <label style="font-weight:600;">Module Access Permissions</label>
                        <div style="display:grid; grid-template-columns:1fr 1fr; gap:8px; margin-top:4px; font-size:12px; background:#f8fafc; padding:10px; border-radius:8px; border:1px solid #e2e8f0;">
                            <label style="display:flex; align-items:center; gap:6px; cursor:pointer;"><input type="checkbox" id="edit-perm-sales" ${p.sales ? 'checked' : ''}> 🛒 Sales</label>
                            <label style="display:flex; align-items:center; gap:6px; cursor:pointer;"><input type="checkbox" id="edit-perm-repairs" ${p.repairs ? 'checked' : ''}> 🔧 Repairs</label>
                            <label style="display:flex; align-items:center; gap:6px; cursor:pointer;"><input type="checkbox" id="edit-perm-stock" ${p.stock || p.purchases ? 'checked' : ''}> 📦 Stock</label>
                            <label style="display:flex; align-items:center; gap:6px; cursor:pointer;"><input type="checkbox" id="edit-perm-expenses" ${p.expenses ? 'checked' : ''}> 💸 Expenses</label>
                            <label style="display:flex; align-items:center; gap:6px; cursor:pointer;"><input type="checkbox" id="edit-perm-used" ${p.used_mobiles ? 'checked' : ''}> 📱 Used Mobiles</label>
                            <label style="display:flex; align-items:center; gap:6px; cursor:pointer;"><input type="checkbox" id="edit-perm-customers" ${p.customers ? 'checked' : ''}> 👥 Customers</label>
                        </div>
                    </div>
                    <div style="display:flex; gap:10px; margin-top:16px;">
                        <button type="submit" class="btn-primary" style="flex:1;">Save Changes</button>
                        <button type="button" class="btn-sm" onclick="closeModal()">Cancel</button>
                    </div>
                </form>
            `);
        }

        async function saveAdminEditStaff(e, shopId, staffId) {
            e.preventDefault();
            const pwd = document.getElementById('edit-staff-password').value.trim();
            const body = {
                name: document.getElementById('edit-staff-name').value.trim(),
                mobile: document.getElementById('edit-staff-mobile').value.trim(),
                designation: document.getElementById('edit-staff-designation').value.trim(),
                salary: document.getElementById('edit-staff-salary').value ? parseFloat(document.getElementById('edit-staff-salary').value) : null,
                joining_date: document.getElementById('edit-staff-joining').value || null,
                email: document.getElementById('edit-staff-email').value.trim() || null,
                permissions: {
                    sales: document.getElementById('edit-perm-sales').checked,
                    repairs: document.getElementById('edit-perm-repairs').checked,
                    purchases: document.getElementById('edit-perm-stock').checked,
                    expenses: document.getElementById('edit-perm-expenses').checked,
                    used_mobiles: document.getElementById('edit-perm-used').checked,
                    customers: document.getElementById('edit-perm-customers').checked,
                }
            };
            if (pwd.length > 0) {
                body.password = pwd;
            }

            const res = await apiFetch(`/shops/${shopId}/staff/${staffId}`, 'PUT', body);
            if (res && res.success) {
                alert('Staff member updated successfully!');
                closeModal();
                openShopDetails(shopId);
                loadShopsView();
            } else {
                alert(res.message || 'Failed to update staff member');
            }
        }

        async function adminToggleStaffStatus(shopId, staffId) {
            const res = await apiFetch(`/shops/${shopId}/staff/${staffId}/toggle-status`, 'POST');
            if (res && res.success) {
                openShopDetails(shopId);
                loadShopsView();
            } else {
                alert(res.message || 'Failed to toggle staff status');
            }
        }

        async function adminDeleteStaff(shopId, staffId, staffName) {
            if (!confirm(`Are you sure you want to delete staff member "${staffName}"? This will permanently delete their account and revoke app login.`)) return;
            const res = await apiFetch(`/shops/${shopId}/staff/${staffId}`, 'DELETE');
            if (res && res.success) {
                alert('Staff member deleted successfully.');
                openShopDetails(shopId);
                loadShopsView();
            } else {
                alert(res.message || 'Failed to delete staff member');
            }
        }

        async function openCustomPricingModal(shopId, shopName) {
            openModal(`Custom Pricing & Discounts — ${shopName}`, '<div style="padding:24px; text-align:center; color:#64748b;">Loading shop details & plans...</div>');

            const [shopRes, plansRes] = await Promise.all([
                apiFetch(`/shops/${shopId}`),
                apiFetch('/plans')
            ]);

            if (!shopRes || !shopRes.success) {
                openModal(`Custom Pricing — ${shopName}`, '<div style="color:red; padding:16px;">Failed to load shop details.</div>');
                return;
            }

            const shop = shopRes.data;
            const plans = (plansRes && plansRes.data) ? (plansRes.data.data || plansRes.data) : [];
            const activePlans = Array.isArray(plans) ? plans.filter(p => p.status === 'active') : [];
            const planPrices = (shop.custom_plan_prices && typeof shop.custom_plan_prices === 'object') ? shop.custom_plan_prices : {};

            const plansHtml = activePlans.map(p => {
                const currentVal = planPrices[p.id] !== undefined ? planPrices[p.id] : '';
                return `
                    <tr style="border-bottom:1px solid #e2e8f0;">
                        <td style="padding:8px 10px; font-weight:600; color:#0f172a;">${p.name} <span style="font-size:11px; color:#64748b;">(${p.billing_period})</span></td>
                        <td style="padding:8px 10px; color:#64748b; font-weight:600;">₹${parseFloat(p.price).toFixed(2)}</td>
                        <td style="padding:8px 10px;">
                            <div style="display:flex; align-items:center; gap:4px;">
                                <span style="font-weight:bold; color:#0f172a;">₹</span>
                                <input type="number" step="1" min="1" max="50000" class="form-control plan-custom-price-input" data-plan-id="${p.id}" value="${currentVal}" placeholder="Standard (₹${parseFloat(p.price).toFixed(0)})" style="padding:5px 8px; font-size:12px; width:140px; border-radius:6px;">
                            </div>
                        </td>
                    </tr>
                `;
            }).join('');

            openModal(`Custom Pricing & Discounts — ${shopName}`, `
                <form onsubmit="saveShopCustomPricing(event, ${shopId})">
                    <p style="font-size:13px; color:#475569; margin-bottom:14px; line-height:1.5;">
                        Configure special/discounted pricing for <strong>${shopName}</strong>. This shop will see these custom prices in their mobile app when purchasing or renewing subscriptions.
                    </p>

                    <div style="display:grid; grid-template-columns:1fr 1fr; gap:12px; margin-bottom:14px;">
                        <div class="form-group" style="margin-bottom:0;">
                            <label style="font-weight:600; font-size:12px;">Shop-Wide Discount (% OFF)</label>
                            <div style="display:flex; align-items:center; gap:6px;">
                                <input type="number" id="shop-custom-discount-percent" class="form-control" value="${shop.custom_discount_percent !== null && shop.custom_discount_percent !== undefined ? shop.custom_discount_percent : ''}" placeholder="e.g. 20 (for 20% off all plans)" min="0" max="99" step="1">
                                <span style="font-weight:bold; color:#475569;">%</span>
                            </div>
                            <small style="color:#64748b; font-size:11px;">Optional. Applies to plans without specific custom price.</small>
                        </div>

                        <div class="form-group" style="margin-bottom:0;">
                            <label style="font-weight:600; font-size:12px;">Staff Add-on Price (₹ / Day)</label>
                            <div style="display:flex; align-items:center; gap:4px;">
                                <span style="font-weight:bold; color:#475569;">₹</span>
                                <input type="number" id="shop-custom-staff-rate" class="form-control" value="${shop.custom_staff_price_per_day !== null && shop.custom_staff_price_per_day !== undefined ? shop.custom_staff_price_per_day : ''}" placeholder="Default (₹2.00)" min="0" max="1000" step="0.5">
                            </div>
                            <small style="color:#64748b; font-size:11px;">Leave empty to use global default (₹2.00/day).</small>
                        </div>
                    </div>

                    <div style="background:#f8fafc; border:1px solid #e2e8f0; border-radius:8px; padding:10px 14px; margin-bottom:14px; display:flex; align-items:flex-start; gap:10px;">
                        <input type="checkbox" id="shop-custom-discount-one-time" ${shop.custom_discount_is_one_time ? 'checked' : ''} style="width:18px; height:18px; accent-color:#059669; margin-top:2px; cursor:pointer;">
                        <div>
                            <label for="shop-custom-discount-one-time" style="font-weight:700; font-size:12.5px; color:#0f172a; cursor:pointer; margin-bottom:2px; display:block;">
                                One-Time Use Only (Expires immediately after next purchase)
                            </label>
                            <div style="font-size:11px; color:#64748b; line-height:1.4;">
                                When checked, discount applies only to this shop's <strong>next purchase</strong>. Once completed, standard pricing automatically restores for this shop.
                            </div>
                        </div>
                    </div>

                    <div style="margin-bottom:14px;">
                        <label style="font-weight:700; font-size:12.5px; color:#0f172a; margin-bottom:6px; display:block;">
                            Specific Plan Custom Prices (Override per plan)
                        </label>
                        <div style="max-height:220px; overflow-y:auto; border:1px solid #cbd5e1; border-radius:6px;">
                            <table style="width:100%; border-collapse:collapse; font-size:12px;">
                                <thead>
                                    <tr style="background:#f1f5f9; border-bottom:1px solid #cbd5e1; text-align:left;">
                                        <th style="padding:8px 10px;">Plan Name</th>
                                        <th style="padding:8px 10px;">Standard Price</th>
                                        <th style="padding:8px 10px;">Custom Price (₹)</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    ${plansHtml}
                                </tbody>
                            </table>
                        </div>
                        <small style="color:#64748b; font-size:11px; margin-top:4px; display:block;">Leave a plan price blank to use standard price or % discount.</small>
                    </div>

                    <div style="display:grid; grid-template-columns:1fr 1fr; gap:12px; margin-bottom:16px;">
                        <div class="form-group" style="margin-bottom:0;">
                            <label style="font-weight:600; font-size:12px;">Discount Valid Until Date</label>
                            <input type="date" id="shop-custom-discount-date" class="form-control" value="${shop.custom_discount_valid_until || ''}">
                            <small style="color:#64748b; font-size:11px;">Leave empty for permanent / lifetime discount.</small>
                        </div>

                        <div class="form-group" style="margin-bottom:0;">
                            <label style="font-weight:600; font-size:12px;">Admin Note / Offer Reason</label>
                            <input type="text" id="shop-custom-discount-note" class="form-control" value="${shop.custom_discount_note || ''}" placeholder="e.g. Diwali Special, Early Partner">
                            <small style="color:#64748b; font-size:11px;">Internal reference note.</small>
                        </div>
                    </div>

                    <div style="margin-top:20px; display:flex; gap:10px;">
                        <button type="submit" class="btn-primary" style="flex:1; background:#059669; border-color:#059669;">💾 Save Custom Pricing</button>
                        <button type="button" class="btn-sm" style="background:#fee2e2; color:#b91c1c; border-color:#fca5a5;" onclick="clearShopCustomPricing(${shopId})">Clear All Discounts</button>
                        <button type="button" class="btn-sm" onclick="closeModal()">Cancel</button>
                    </div>
                </form>
            `, '700px');
        }

        async function saveShopCustomPricing(e, shopId) {
            e.preventDefault();
            const percentVal = document.getElementById('shop-custom-discount-percent').value.trim();
            const staffRateVal = document.getElementById('shop-custom-staff-rate').value.trim();
            const dateVal = document.getElementById('shop-custom-discount-date').value.trim();
            const noteVal = document.getElementById('shop-custom-discount-note').value.trim();

            const customPrices = {};
            document.querySelectorAll('.plan-custom-price-input').forEach(input => {
                const planId = input.getAttribute('data-plan-id');
                const val = input.value.trim();
                if (val !== '' && !isNaN(val)) {
                    customPrices[planId] = parseFloat(val);
                }
            });

            const body = {
                custom_discount_percent: percentVal !== '' ? parseFloat(percentVal) : null,
                custom_plan_prices: Object.keys(customPrices).length > 0 ? customPrices : null,
                custom_staff_price_per_day: staffRateVal !== '' ? parseFloat(staffRateVal) : null,
                custom_discount_valid_until: dateVal !== '' ? dateVal : null,
                custom_discount_note: noteVal !== '' ? noteVal : null,
                custom_discount_is_one_time: document.getElementById('shop-custom-discount-one-time') ? document.getElementById('shop-custom-discount-one-time').checked : false,
            };

            const res = await apiFetch(`/shops/${shopId}/custom-pricing`, 'POST', body);
            if (res && res.success) {
                alert('Shop custom pricing and discounts saved successfully!');
                closeModal();
                loadShopsView();
            } else {
                alert(res.message || 'Failed to update custom pricing');
            }
        }

        async function clearShopCustomPricing(shopId) {
            if (!confirm('Are you sure you want to remove all custom discounts for this shop and revert to standard prices?')) return;
            const res = await apiFetch(`/shops/${shopId}/custom-pricing`, 'POST', {
                custom_discount_percent: null,
                custom_plan_prices: null,
                custom_staff_price_per_day: null,
                custom_discount_valid_until: null,
                custom_discount_note: null,
                custom_discount_is_one_time: false,
            });
            if (res && res.success) {
                alert('Custom pricing cleared. Standard prices restored for this shop.');
                closeModal();
                loadShopsView();
            } else {
                alert(res.message || 'Failed to clear custom pricing');
            }
        }

        // PLATFORM-WIDE BULK DISCOUNT MODAL & ACTIONS
        function openBulkDiscountModal() {
            openModal(`🏷️ Apply Discount Across ALL Shops`, `
                <form onsubmit="saveBulkDiscount(event)">
                    <div style="background:#eff6ff; border:1px solid #bfdbfe; border-radius:10px; padding:12px 14px; margin-bottom:16px;">
                        <div style="display:flex; align-items:flex-start; gap:8px;">
                            <span style="font-size:18px;">💡</span>
                            <div style="font-size:12px; color:#1e40af; line-height:1.5;">
                                <strong>Platform-wide Discount Campaign:</strong> This will apply the specified discount percentage to <strong>every shop</strong> on the platform.
                            </div>
                        </div>
                    </div>

                    <div style="margin-bottom:14px;">
                        <label style="font-weight:700; font-size:12.5px; color:#0f172a; margin-bottom:6px; display:block;">
                            Discount Percentage (% OFF for All Shops) *
                        </label>
                        <div style="display:flex; align-items:center; gap:8px;">
                            <input type="number" id="bulk-discount-percent" class="form-control" placeholder="e.g. 20" min="1" max="99" step="1" required style="font-size:16px; font-weight:700; max-width:180px;">
                            <span style="font-size:18px; font-weight:800; color:#475569;">% OFF</span>
                        </div>
                        <small style="color:#64748b; font-size:11px;">Applies to all subscription plans across all shops.</small>
                    </div>

                    <div style="background:#f8fafc; border:1px solid #cbd5e1; border-radius:10px; padding:14px; margin-bottom:14px;">
                        <div style="display:flex; align-items:flex-start; gap:10px;">
                            <input type="checkbox" id="bulk-discount-one-time" checked style="width:20px; height:20px; accent-color:#4f46e5; margin-top:2px; cursor:pointer;">
                            <div>
                                <label for="bulk-discount-one-time" style="font-weight:700; font-size:13px; color:#0f172a; cursor:pointer; margin-bottom:2px; display:block;">
                                    One-Time Purchase Only per shop (Recommended)
                                </label>
                                <div style="font-size:11.5px; color:#64748b; line-height:1.4;">
                                    Every shop gets this discount for their next purchase. Once a shop completes payment, the discount is <strong>automatically removed for that specific shop</strong>, while remaining active for all other shops until they also purchase!
                                </div>
                            </div>
                        </div>
                    </div>

                    <div style="display:grid; grid-template-columns:1fr 1fr; gap:12px; margin-bottom:16px;">
                        <div class="form-group" style="margin-bottom:0;">
                            <label style="font-weight:600; font-size:12px;">Valid Until Expiry Date</label>
                            <input type="date" id="bulk-discount-date" class="form-control">
                            <small style="color:#64748b; font-size:11px;">Optional. Automatically expires after this date.</small>
                        </div>

                        <div class="form-group" style="margin-bottom:0;">
                            <label style="font-weight:600; font-size:12px;">Campaign Name / Note</label>
                            <input type="text" id="bulk-discount-note" class="form-control" placeholder="e.g. Festival Special Offer 20% OFF">
                            <small style="color:#64748b; font-size:11px;">Visible to shops on app discount banner.</small>
                        </div>
                    </div>

                    <div style="margin-top:20px; display:flex; gap:10px;">
                        <button type="submit" class="btn-primary" style="flex:1; background:#4f46e5; border-color:#4f46e5;">🚀 Apply to All Shops</button>
                        <button type="button" class="btn-sm" style="background:#fee2e2; color:#b91c1c; border-color:#fca5a5;" onclick="clearBulkDiscount()">Clear All Shops Discount</button>
                        <button type="button" class="btn-sm" onclick="closeModal()">Cancel</button>
                    </div>
                </form>
            `, '620px');
        }

        async function saveBulkDiscount(e) {
            e.preventDefault();
            const percent = document.getElementById('bulk-discount-percent').value.trim();
            const isOneTime = document.getElementById('bulk-discount-one-time').checked;
            const validUntil = document.getElementById('bulk-discount-date').value.trim();
            const note = document.getElementById('bulk-discount-note').value.trim();

            if (!percent || isNaN(percent) || parseFloat(percent) <= 0) {
                alert('Please enter a valid discount percentage (e.g. 20).');
                return;
            }

            const confirmMsg = `Are you sure you want to apply a ${percent}% discount across ALL shops?` +
                (isOneTime ? `\n\nNote: Each shop will consume this discount on their next purchase, and it will automatically be removed for that shop upon payment.` : '');
            if (!confirm(confirmMsg)) return;

            const res = await apiFetch('/shops/bulk-custom-pricing', 'POST', {
                discount_percent: parseFloat(percent),
                is_one_time: isOneTime,
                valid_until: validUntil || null,
                note: note || null,
            });

            if (res && res.success) {
                alert(res.message || 'Bulk discount applied successfully across all shops!');
                closeModal();
                loadShopsView();
            } else {
                alert(res?.message || 'Failed to apply bulk discount.');
            }
        }

        async function clearBulkDiscount() {
            if (!confirm('Are you sure you want to remove all custom discounts from ALL shops?')) return;
            const res = await apiFetch('/shops/bulk-clear-pricing', 'POST');
            if (res && res.success) {
                alert(res.message || 'Bulk discounts cleared.');
                closeModal();
                loadShopsView();
            } else {
                alert(res?.message || 'Failed to clear bulk discounts.');
            }
        }

        // 3. USERS VIEW
        async function loadUsersView(page = 1, search = '', role = '', openedFilter = '') {
            const content = getContentContainer();
            const data = await apiFetch(`/users?page=${page}&search=${encodeURIComponent(search)}&role=${role}&opened_filter=${openedFilter}`);
            if (!data || !data.success) return;
            const pageData = data.data;
            const users = pageData.data || [];

            content.innerHTML = `
                <div class="card-table">
                    <div class="table-toolbar">
                        <div style="display:flex; gap:10px; flex:1; min-width:280px;">
                            <div class="search-box" style="flex:1;">
                                <input type="text" id="users-search-input" placeholder="Search user name, mobile, email, shop..." value="${search}" oninput="debounceSearch(() => loadUsersView(1, document.getElementById('users-search-input').value, '${role}', '${openedFilter}'))">
                            </div>
                        </div>
                        <div style="display:flex; gap:10px; flex-wrap:wrap; align-items:center;">
                            <select class="filter-select" onchange="loadUsersView(1, '${search}', this.value, '${openedFilter}')">
                                <option value="">Role: All Roles</option>
                                <option value="owner" ${role === 'owner' ? 'selected' : ''}>Shop Owner</option>
                                <option value="technician" ${role === 'technician' ? 'selected' : ''}>Technician</option>
                                <option value="staff" ${role === 'staff' ? 'selected' : ''}>Staff</option>
                                <option value="admin" ${role === 'admin' ? 'selected' : ''}>SaaS Admin</option>
                            </select>
                            <select class="filter-select" onchange="loadUsersView(1, '${search}', '${role}', this.value)">
                                <option value="">App Activity: All Users</option>
                                <option value="today" ${openedFilter === 'today' ? 'selected' : ''}>🟢 Opened App Today</option>
                                <option value="never" ${openedFilter === 'never' ? 'selected' : ''}>Never Opened App</option>
                            </select>
                            ${(search || role || openedFilter) ? `<button class="btn-sm" style="background:#e2e8f0; color:#334155;" onclick="loadUsersView(1, '', '', '')">Clear Filters</button>` : ''}
                        </div>
                    </div>
                    <div class="table-responsive">
                    <table>
                        <thead>
                            <tr>
                                <th>Name</th>
                                <th>Mobile / Email</th>
                                <th>Associated Shop</th>
                                <th>User Role</th>
                                <th>Last Mobile App Open</th>
                                <th>Registered Date</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${users.length === 0 ? `<tr><td colspan="6" style="text-align:center; padding:30px; color:#94a3b8;">No users found matching filter criteria.</td></tr>` : ''}
                            ${users.map(u => {
                                const lastOpen = u.last_app_opened_at ? new Date(u.last_app_opened_at) : null;
                                const isToday = lastOpen && (new Date().toDateString() === lastOpen.toDateString());
                                const lastOpenBadge = lastOpen
                                    ? (isToday
                                        ? `<span class="badge badge-active" style="background:#dcfce7; color:#15803d; font-weight:600; display:inline-flex; align-items:center; gap:4px;">🟢 Today ${lastOpen.toLocaleTimeString([], {hour:'2-digit', minute:'2-digit'})}</span>`
                                        : `<span style="font-size:12px; color:#64748b;">${lastOpen.toLocaleDateString()} ${lastOpen.toLocaleTimeString([], {hour:'2-digit', minute:'2-digit'})}</span>`)
                                    : `<span style="color:#94a3b8; font-size:12px;">Never</span>`;

                                return `
                                <tr>
                                    <td><strong>${u.name}</strong></td>
                                    <td>${u.mobile || u.phone || 'N/A'}${u.email ? `<br><span style="font-size:11px; color:#64748b;">${u.email}</span>` : ''}</td>
                                    <td>${u.shop ? u.shop.name : 'N/A (Admin)'}</td>
                                    <td><span class="badge badge-resolved">${u.role}</span></td>
                                    <td>${lastOpenBadge}</td>
                                    <td>${new Date(u.created_at).toLocaleDateString()}</td>
                                </tr>
                                `;
                            }).join('')}
                        </tbody>
                    </table>
                    </div>
                    ${renderPagination(pageData, 'loadUsersView', search, role, openedFilter)}
                </div>
            `;
        }

        // 4. SUBSCRIPTIONS VIEW
        async function loadSubscriptionsView(page = 1, search = '', status = '', paymentStatus = '') {
            const content = getContentContainer();
            const data = await apiFetch(`/subscriptions?page=${page}&search=${encodeURIComponent(search)}&status=${status}&payment_status=${paymentStatus}`);
            if (!data || !data.success) return;
            const pageData = data.data;
            const subs = pageData.data || [];

            content.innerHTML = `
                <div class="card-table">
                    <div class="table-toolbar">
                        <div style="display:flex; gap:10px; flex:1; min-width:280px;">
                            <div class="search-box" style="flex:1;">
                                <input type="text" id="subs-search-input" placeholder="Search by shop name, owner..." value="${search}" oninput="debounceSearch(() => loadSubscriptionsView(1, document.getElementById('subs-search-input').value, '${status}', '${paymentStatus}'))">
                            </div>
                        </div>
                        <div style="display:flex; gap:10px; flex-wrap:wrap; align-items:center;">
                            <select class="filter-select" onchange="loadSubscriptionsView(1, '${search}', this.value, '${paymentStatus}')">
                                <option value="">Status: All</option>
                                <option value="trial" ${status === 'trial' ? 'selected' : ''}>Trial</option>
                                <option value="active" ${status === 'active' ? 'selected' : ''}>Active</option>
                                <option value="expired" ${status === 'expired' ? 'selected' : ''}>Expired</option>
                                <option value="cancelled" ${status === 'cancelled' ? 'selected' : ''}>Cancelled</option>
                            </select>
                            <select class="filter-select" onchange="loadSubscriptionsView(1, '${search}', '${status}', this.value)">
                                <option value="">Payment: All</option>
                                <option value="paid" ${paymentStatus === 'paid' ? 'selected' : ''}>Paid</option>
                                <option value="pending" ${paymentStatus === 'pending' ? 'selected' : ''}>Pending</option>
                                <option value="free" ${paymentStatus === 'free' ? 'selected' : ''}>Free</option>
                            </select>
                            ${(search || status || paymentStatus) ? `<button class="btn-sm" style="background:#e2e8f0; color:#334155;" onclick="loadSubscriptionsView(1, '', '', '')">Clear Filters</button>` : ''}
                        </div>
                    </div>
                    <div class="table-responsive">
                    <table>
                        <thead>
                            <tr>
                                <th>Shop Name</th>
                                <th>Current Plan</th>
                                <th>Subscription Status</th>
                                <th>Payment Status</th>
                                <th>Expiry Date</th>
                                <th>Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${subs.length === 0 ? `<tr><td colspan="6" style="text-align:center; padding:30px; color:#94a3b8;">No subscriptions found matching filter criteria.</td></tr>` : ''}
                            ${subs.map(s => `
                                <tr>
                                    <td><strong>${s.shop ? s.shop.name : 'Shop #' + s.shop_id}</strong></td>
                                    <td>${s.plan ? s.plan.name : 'Default Plan'}</td>
                                    <td><span class="badge ${s.status === 'active' ? 'badge-active' : (s.status === 'expired' ? 'badge-inactive' : 'badge-trial')}">${s.status.toUpperCase()}</span></td>
                                    <td><span class="badge ${s.payment_status === 'paid' ? 'badge-active' : 'badge-trial'}">${s.payment_status}</span></td>
                                    <td>${s.expiry_date ? new Date(s.expiry_date).toLocaleDateString() : 'N/A'}</td>
                                    <td>
                                        <button class="btn-sm" onclick="editSubscription(${s.id}, ${s.plan_id || 1}, '${s.status}', '${s.expiry_date ? s.expiry_date.substring(0, 10) : ''}', '${s.payment_status}')">Manage</button>
                                    </td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                    </div>
                    ${renderPagination(pageData, 'loadSubscriptionsView', search, status, paymentStatus)}
                </div>
            `;
        }

        async function editSubscription(id, currentPlanId, currentStatus, currentExpiry, currentPaymentStatus) {
            openModal('Manage Subscription', `
                <form onsubmit="saveSubscriptionUpdate(event, ${id})">
                    <div class="form-group">
                        <label>Subscription Status</label>
                        <select id="sub-edit-status" class="form-control">
                            <option value="trial" ${currentStatus === 'trial' ? 'selected' : ''}>Trial</option>
                            <option value="active" ${currentStatus === 'active' ? 'selected' : ''}>Active</option>
                            <option value="expired" ${currentStatus === 'expired' ? 'selected' : ''}>Expired</option>
                            <option value="cancelled" ${currentStatus === 'cancelled' ? 'selected' : ''}>Cancelled</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Payment Status</label>
                        <select id="sub-edit-payment" class="form-control">
                            <option value="paid" ${currentPaymentStatus === 'paid' ? 'selected' : ''}>Paid</option>
                            <option value="pending" ${currentPaymentStatus === 'pending' ? 'selected' : ''}>Pending</option>
                            <option value="free" ${currentPaymentStatus === 'free' ? 'selected' : ''}>Free</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Expiry Date</label>
                        <input type="date" id="sub-edit-expiry" class="form-control" value="${currentExpiry}">
                    </div>
                    <div style="margin-top:20px; display:flex; gap:10px;">
                        <button type="submit" class="btn-primary" style="flex:1;">Update Subscription</button>
                        <button type="button" class="btn-sm" onclick="closeModal()">Cancel</button>
                    </div>
                </form>
            `);
        }

        async function saveSubscriptionUpdate(e, id) {
            e.preventDefault();
            const body = {
                status: document.getElementById('sub-edit-status').value,
                payment_status: document.getElementById('sub-edit-payment').value,
                expiry_date: document.getElementById('sub-edit-expiry').value,
            };
            const data = await apiFetch(`/subscriptions/${id}/status`, 'PUT', body);
            if (data && data.success) {
                alert('Subscription updated successfully!');
                closeModal();
                loadSubscriptionsView();
            } else {
                alert(data.message || 'Failed to update subscription');
            }
        }

        // 5. PAYMENTS VIEW
        async function loadPaymentsView(page = 1, search = '', status = '') {
            const content = getContentContainer();
            const data = await apiFetch(`/payments?page=${page}&search=${encodeURIComponent(search)}&status=${status}`);
            if (!data || data.status !== 'success') return;
            const pageData = data.data;
            const payments = pageData.data || [];

            content.innerHTML = `
                <div class="card-table">
                    <div class="table-toolbar">
                        <div style="display:flex; gap:10px; flex:1; min-width:280px;">
                            <div class="search-box" style="flex:1;">
                                <input type="text" id="payments-search-input" placeholder="Search order ID, payment ID, shop..." value="${search}" oninput="debounceSearch(() => loadPaymentsView(1, document.getElementById('payments-search-input').value, '${status}'))">
                            </div>
                        </div>
                        <div style="display:flex; gap:10px; flex-wrap:wrap; align-items:center;">
                            <select class="filter-select" onchange="loadPaymentsView(1, '${search}', this.value)">
                                <option value="">Status: All</option>
                                <option value="successful" ${status === 'successful' ? 'selected' : ''}>Successful</option>
                                <option value="pending" ${status === 'pending' ? 'selected' : ''}>Pending</option>
                                <option value="failed" ${status === 'failed' ? 'selected' : ''}>Failed</option>
                            </select>
                            ${(search || status) ? `<button class="btn-sm" style="background:#e2e8f0; color:#334155;" onclick="loadPaymentsView(1, '', '')">Clear Filters</button>` : ''}
                        </div>
                    </div>
                    <div class="table-responsive">
                    <table>
                        <thead>
                            <tr>
                                <th>Shop Name</th>
                                <th>Order ID</th>
                                <th>Payment ID</th>
                                <th>Plan Price</th>
                                <th>Points Used</th>
                                <th>Cash Paid</th>
                                <th>Method</th>
                                <th>Status</th>
                                <th>Timestamp</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${payments.length === 0 ? `<tr><td colspan="9" style="text-align:center; padding:30px; color:#94a3b8;">No payment records found matching filter criteria.</td></tr>` : ''}
                            ${payments.map(p => {
                                const gw = (p.gateway_response && typeof p.gateway_response === 'object') ? p.gateway_response : {};
                                const cashPaid = parseFloat(p.amount || 0);
                                const ptsUsed = parseFloat(gw.points_used || 0);
                                const origAmt = gw.original_amount !== undefined && gw.original_amount !== null
                                    ? parseFloat(gw.original_amount)
                                    : (cashPaid + ptsUsed);
                                return `
                                <tr>
                                    <td><strong>${p.shop ? p.shop.name : 'Shop #' + p.shop_id}</strong></td>
                                    <td><span style="font-family:monospace; font-size:12px;">${p.order_id}</span></td>
                                    <td><span style="font-family:monospace; font-size:12px;">${p.payment_id || '—'}</span></td>
                                    <td>₹${origAmt.toFixed(2)}</td>
                                    <td>${ptsUsed > 0 ? `<span class="badge" style="background:#eef2ff; color:#4f46e5; font-weight:700;">-${ptsUsed.toFixed(2)} pts</span>` : '<span style="color:#94a3b8;">—</span>'}</td>
                                    <td><strong style="color:#059669;">₹${cashPaid.toFixed(2)}</strong></td>
                                    <td>${p.payment_method || 'Razorpay'}</td>
                                    <td><span class="badge ${p.status === 'successful' ? 'badge-active' : (p.status === 'failed' ? 'badge-inactive' : 'badge-trial')}">${p.status.toUpperCase()}</span></td>
                                    <td>${new Date(p.created_at).toLocaleString()}</td>
                                </tr>
                            `;}).join('')}
                        </tbody>
                    </table>
                    </div>
                    ${renderPagination(pageData, 'loadPaymentsView', search, status)}
                </div>
            `;
        }

        // 6. PLANS VIEW
        async function loadPlansView(search = '', status = '') {
            const content = getContentContainer();
            const [plansRes, rateRes] = await Promise.all([
                apiFetch('/plans'),
                apiFetch('/settings/staff-addon-rate')
            ]);

            if (!plansRes || !plansRes.success) return;
            let plans = plansRes.data || [];
            const currentDailyRate = (rateRes && rateRes.data && rateRes.data.staff_price_per_day !== undefined)
                ? parseFloat(rateRes.data.staff_price_per_day).toFixed(2)
                : '2.00';

            if (search) {
                const sLower = search.toLowerCase();
                plans = plans.filter(p => p.name.toLowerCase().includes(sLower) || p.billing_period.toLowerCase().includes(sLower));
            }
            if (status) {
                plans = plans.filter(p => p.status === status);
            }

            content.innerHTML = `
                <!-- Staff Addon Daily Price Config Card -->
                <div class="card-table" style="margin-bottom: 20px; padding: 18px 20px; background: linear-gradient(135deg, #f8fafc 0%, #eff6ff 100%); border: 1px solid #bfdbfe;">
                    <div style="display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:16px;">
                        <div style="flex:1; min-width:280px;">
                            <h3 style="margin:0 0 6px 0; font-size:16px; color:#1e293b; display:flex; align-items:center; gap:8px;">
                                <span>👥</span> Staff Logins Add-on Daily Rate
                            </h3>
                            <p style="margin:0; font-size:13px; color:#64748b; line-height:1.4;">
                                Rate charged to shop owners per staff login account per remaining day of their active subscription. (Technicians are free).
                                <br><small style="color:#2563eb;">Formula: Remaining Plan Days × Daily Rate × Added Staff Logins = Add-on Amount</small>
                            </p>
                        </div>
                        <form onsubmit="saveStaffAddonDailyRate(event)" style="display:flex; align-items:center; gap:10px; background:white; padding:10px 14px; border-radius:10px; border:1px solid #cbd5e1; box-shadow:0 1px 3px rgba(0,0,0,0.05);">
                            <div style="font-weight:700; color:#1e293b; font-size:14px;">₹</div>
                            <input type="number" step="0.10" min="0" id="staff-addon-daily-rate" value="${currentDailyRate}" style="width:90px; padding:6px 10px; font-weight:700; font-size:15px; border:1px solid #cbd5e1; border-radius:6px; text-align:center;" required>
                            <div style="font-size:12px; color:#64748b; font-weight:600;">/ Day / Staff</div>
                            <button type="submit" class="btn-primary" style="padding:7px 16px; font-size:13px; font-weight:600;">Save Rate</button>
                        </form>
                    </div>
                    <div style="display:flex; gap:14px; margin-top:12px; padding-top:12px; border-top:1px dashed #cbd5e1; font-size:12px; color:#475569; flex-wrap:wrap;">
                        <div><strong>Reference (at ₹${currentDailyRate}/day):</strong></div>
                        <div>30 Days (1 Month): <strong>₹${(parseFloat(currentDailyRate) * 30).toFixed(0)}</strong></div>
                        <div>54 Days: <strong>₹${(parseFloat(currentDailyRate) * 54).toFixed(0)}</strong></div>
                        <div>90 Days (3 Months): <strong>₹${(parseFloat(currentDailyRate) * 90).toFixed(0)}</strong></div>
                        <div>180 Days (6 Months): <strong>₹${(parseFloat(currentDailyRate) * 180).toFixed(0)}</strong></div>
                    </div>
                </div>

                <div class="card-table">
                    <div class="table-toolbar">
                        <div style="display:flex; gap:10px; flex:1; min-width:280px;">
                            <div class="search-box" style="flex:1;">
                                <input type="text" id="plans-search-input" placeholder="Search plan name, billing period..." value="${search}" oninput="debounceSearch(() => loadPlansView(document.getElementById('plans-search-input').value, '${status}'))">
                            </div>
                        </div>
                        <div style="display:flex; gap:10px; flex-wrap:wrap; align-items:center;">
                            <select class="filter-select" onchange="loadPlansView('${search}', this.value)">
                                <option value="">Status: All</option>
                                <option value="active" ${status === 'active' ? 'selected' : ''}>Active</option>
                                <option value="inactive" ${status === 'inactive' ? 'selected' : ''}>Inactive</option>
                            </select>
                            ${(search || status) ? `<button class="btn-sm" style="background:#e2e8f0; color:#334155;" onclick="loadPlansView('', '')">Clear Filters</button>` : ''}
                            <button class="btn-primary" style="padding:8px 16px; width:auto; font-size:13px;" onclick="createPlanModal()">+ Create New Plan</button>
                        </div>
                    </div>
                    <div class="table-responsive">
                    <table>
                        <thead>
                            <tr>
                                <th>Plan Name</th>
                                <th>Price</th>
                                <th>Billing Cycle</th>
                                <th>Sort Order</th>
                                <th>Status</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${plans.length === 0 ? `<tr><td colspan="6" style="text-align:center; padding:30px; color:#94a3b8;">No plans found matching filter criteria.</td></tr>` : ''}
                            ${plans.map(p => `
                                <tr>
                                    <td><strong>${p.name}</strong></td>
                                    <td><strong>₹${parseFloat(p.price).toFixed(2)}</strong></td>
                                    <td>${p.billing_period}</td>
                                    <td>${p.sort_order || 0}</td>
                                    <td><span class="badge ${p.status === 'active' ? 'badge-active' : 'badge-inactive'}">${p.status}</span></td>
                                    <td>
                                        <button class="btn-sm" onclick="editPlanModal(${p.id}, '${p.name.replace(/'/g, "\'")}', ${p.price}, '${p.billing_period}', ${p.sort_order || 0}, '${p.status}', ${p.max_staff_accounts || 0})">Edit</button>
                                        <button class="btn-sm ${p.status === 'active' ? 'btn-danger-sm' : 'btn-success-sm'}" onclick="togglePlanStatus(${p.id})">
                                            ${p.status === 'active' ? 'Disable' : 'Enable'}
                                        </button>
                                    </td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                    </div>
                </div>
            `;
        }

        async function saveStaffAddonDailyRate(e) {
            e.preventDefault();
            const val = parseFloat(document.getElementById('staff-addon-daily-rate').value);
            if (isNaN(val) || val < 0) {
                alert('Please enter a valid rate >= 0');
                return;
            }
            const res = await apiFetch('/settings/staff-addon-rate', 'POST', { staff_price_per_day: val });
            if (res && res.success) {
                alert('Staff add-on daily rate updated successfully to ₹' + val.toFixed(2) + ' / day / staff!');
                loadPlansView();
            } else {
                alert(res.message || 'Failed to update daily rate');
            }
        }

        // PURCHASES VIEW (Admin Data Hub)
        async function loadPurchasesView(page = 1, search = '', paymentStatus = '', shopId = '') {
            const content = getContentContainer();
            const shopOptions = await getShopsDropdownOptions(shopId);
            const data = await apiFetch(`/purchases?page=${page}&search=${encodeURIComponent(search)}&payment_status=${paymentStatus}&shop_id=${shopId}`);
            if (!data || !data.success) return;
            const pageData = data.data;
            const purchases = pageData.data || [];

            content.innerHTML = `
                <div class="card-table">
                    <div class="table-toolbar">
                        <div style="display:flex; gap:10px; flex:1; min-width:280px;">
                            <div class="search-box" style="flex:1;">
                                <input type="text" id="purchases-search-input" placeholder="Search purchase #, vendor name..." value="${search}" oninput="debounceSearch(() => loadPurchasesView(1, document.getElementById('purchases-search-input').value, '${paymentStatus}', '${shopId}'))">
                            </div>
                        </div>
                        <div style="display:flex; gap:10px; flex-wrap:wrap; align-items:center;">
                            <select class="filter-select" onchange="loadPurchasesView(1, '${search}', this.value, '${shopId}')">
                                <option value="">Payment Status: All</option>
                                <option value="paid" ${paymentStatus === 'paid' ? 'selected' : ''}>Paid</option>
                                <option value="partial" ${paymentStatus === 'partial' ? 'selected' : ''}>Partial</option>
                                <option value="pending" ${paymentStatus === 'pending' ? 'selected' : ''}>Pending</option>
                            </select>
                            <select class="filter-select" onchange="loadPurchasesView(1, '${search}', '${paymentStatus}', this.value)">
                                ${shopOptions}
                            </select>
                            ${(search || paymentStatus || shopId) ? `<button class="btn-sm" style="background:#e2e8f0; color:#334155;" onclick="loadPurchasesView(1, '', '', '')">Clear Filters</button>` : ''}
                        </div>
                    </div>
                    <div class="table-responsive">
                    <table>
                        <thead>
                            <tr>
                                <th>Purchase #</th>
                                <th>Vendor</th>
                                <th>Shop</th>
                                <th>Date</th>
                                <th>Grand Total</th>
                                <th>Paid</th>
                                <th>Outstanding</th>
                                <th>Status</th>
                                <th>Stock Added</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${purchases.length === 0 ? `<tr><td colspan="9" style="text-align:center; padding:30px; color:#94a3b8;">No purchase records found matching filter criteria.</td></tr>` : ''}
                            ${purchases.map(p => `
                                <tr>
                                    <td><strong>${p.purchase_number}</strong></td>
                                    <td>${p.vendor_name}</td>
                                    <td>${p.vendor && p.vendor.shop ? p.vendor.shop.name : 'Shop'}</td>
                                    <td>${p.purchase_date}</td>
                                    <td>₹${parseFloat(p.grand_total).toFixed(2)}</td>
                                    <td>₹${parseFloat(p.amount_paid).toFixed(2)}</td>
                                    <td><strong style="color:${p.outstanding_amount > 0 ? '#dc2626' : '#16a34a'};">₹${parseFloat(p.outstanding_amount).toFixed(2)}</strong></td>
                                    <td><span class="badge ${p.payment_status === 'paid' ? 'badge-active' : (p.payment_status === 'partial' ? 'badge-trial' : 'badge-inactive')}">${p.payment_status.toUpperCase()}</span></td>
                                    <td>${p.is_stock_added ? '<span style="color:#16a34a; font-weight:600;">✓ Added</span>' : '<span style="color:#94a3b8;">Pending</span>'}</td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                    </div>
                    ${renderPagination(pageData, 'loadPurchasesView', search, paymentStatus, shopId)}
                </div>
            `;
        }

        // VENDORS VIEW (Admin Data Hub)
        async function loadVendorsView(page = 1, search = '', shopId = '') {
            const content = getContentContainer();
            const shopOptions = await getShopsDropdownOptions(shopId);
            const data = await apiFetch(`/vendors?page=${page}&search=${encodeURIComponent(search)}&shop_id=${shopId}`);
            if (!data || !data.success) return;
            const pageData = data.data;
            const vendors = pageData.data || [];

            content.innerHTML = `
                <div class="card-table">
                    <div class="table-toolbar">
                        <div style="display:flex; gap:10px; flex:1; min-width:280px;">
                            <div class="search-box" style="flex:1;">
                                <input type="text" id="vendors-search-input" placeholder="Search vendor name, phone, email, GST..." value="${search}" oninput="debounceSearch(() => loadVendorsView(1, document.getElementById('vendors-search-input').value, '${shopId}'))">
                            </div>
                        </div>
                        <div style="display:flex; gap:10px; flex-wrap:wrap; align-items:center;">
                            <select class="filter-select" onchange="loadVendorsView(1, '${search}', this.value)">
                                ${shopOptions}
                            </select>
                            ${(search || shopId) ? `<button class="btn-sm" style="background:#e2e8f0; color:#334155;" onclick="loadVendorsView(1, '', '')">Clear Filters</button>` : ''}
                        </div>
                    </div>
                    <div class="table-responsive">
                    <table>
                        <thead>
                            <tr>
                                <th>Vendor Name</th>
                                <th>Contact Mobile</th>
                                <th>Email / GST</th>
                                <th>Total Purchases</th>
                                <th>Total Paid</th>
                                <th>Outstanding</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${vendors.length === 0 ? `<tr><td colspan="6" style="text-align:center; padding:30px; color:#94a3b8;">No vendor suppliers found matching filter criteria.</td></tr>` : ''}
                            ${vendors.map(v => `
                                <tr>
                                    <td><strong>${v.name}</strong></td>
                                    <td>${v.phone}</td>
                                    <td>${v.email || 'N/A'} ${v.gst_number ? `<br><small style="color:#64748b;">GST: ${v.gst_number}</small>` : ''}</td>
                                    <td>₹${parseFloat(v.total_purchase).toFixed(2)}</td>
                                    <td>₹${parseFloat(v.total_paid).toFixed(2)}</td>
                                    <td><strong style="color:${v.outstanding_amount > 0 ? '#dc2626' : '#16a34a'};">₹${parseFloat(v.outstanding_amount).toFixed(2)}</strong></td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                    </div>
                    ${renderPagination(pageData, 'loadVendorsView', search, shopId)}
                </div>
            `;
        }

        function createPlanModal() {
            openModal('Create New Plan', `
                <form onsubmit="saveNewPlan(event)">
                    <div class="form-group">
                        <label>Plan Name</label>
                        <input type="text" id="new-plan-name" class="form-control" placeholder="e.g. 1 Staff Monthly Plan" required>
                    </div>
                    <div class="form-group">
                        <label>Price (INR)</label>
                        <input type="number" step="0.01" id="new-plan-price" class="form-control" placeholder="149.00" required>
                    </div>
                    <div class="form-group">
                        <label>Billing Period</label>
                        <select id="new-plan-period" class="form-control">
                            <option value="monthly">Monthly</option>
                            <option value="3_months">3 Months</option>
                            <option value="6_months">6 Months</option>
                            <option value="annual">Annual (12 Months)</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Max Staff Logins Included (Technicians Free)</label>
                        <input type="number" id="new-plan-max-staff" class="form-control" value="0" min="0">
                        <small style="color:#64748b; font-size:11px;">0 = Solo Owner only, 1 = 1 Staff login, 2 = 2 Staff logins. Technicians are unlimited & free.</small>
                    </div>
                    <div class="form-group">
                        <label>Sort Order</label>
                        <input type="number" id="new-plan-sort" class="form-control" value="1">
                    </div>
                    <div style="margin-top:20px; display:flex; gap:10px;">
                        <button type="submit" class="btn-primary" style="flex:1;">Create Plan</button>
                        <button type="button" class="btn-sm" onclick="closeModal()">Cancel</button>
                    </div>
                </form>
            `);
        }

        async function saveNewPlan(e) {
            e.preventDefault();
            const body = {
                name: document.getElementById('new-plan-name').value,
                price: parseFloat(document.getElementById('new-plan-price').value),
                billing_period: document.getElementById('new-plan-period').value,
                max_staff_accounts: parseInt(document.getElementById('new-plan-max-staff').value) || 0,
                sort_order: parseInt(document.getElementById('new-plan-sort').value) || 0,
                status: 'active',
            };
            const res = await apiFetch('/plans', 'POST', body);
            if (res && res.success) {
                alert('Plan created successfully!');
                closeModal();
                loadPlansView();
            } else {
                alert(res.message || 'Failed to create plan');
            }
        }

        function editPlanModal(id, name, price, period, sort, status, maxStaff = 0) {
            openModal('Edit Subscription Plan', `
                <form onsubmit="savePlanUpdate(event, ${id})">
                    <div class="form-group">
                        <label>Plan Name</label>
                        <input type="text" id="edit-plan-name" class="form-control" value="${name}" required>
                    </div>
                    <div class="form-group">
                        <label>Price (INR)</label>
                        <input type="number" step="0.01" id="edit-plan-price" class="form-control" value="${price}" required>
                    </div>
                    <div class="form-group">
                        <label>Billing Period</label>
                        <select id="edit-plan-period" class="form-control">
                            <option value="monthly" ${period === 'monthly' ? 'selected' : ''}>Monthly</option>
                            <option value="3_months" ${period === '3_months' ? 'selected' : ''}>3 Months</option>
                            <option value="6_months" ${period === '6_months' ? 'selected' : ''}>6 Months</option>
                            <option value="annual" ${period === 'annual' ? 'selected' : ''}>Annual (12 Months)</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Max Staff Logins Included (Technicians Free)</label>
                        <input type="number" id="edit-plan-max-staff" class="form-control" value="${maxStaff}" min="0">
                        <small style="color:#64748b; font-size:11px;">0 = Solo Owner only, 1 = 1 Staff login, 2 = 2 Staff logins. Technicians are unlimited & free.</small>
                    </div>
                    <div class="form-group">
                        <label>Sort Order</label>
                        <input type="number" id="edit-plan-sort" class="form-control" value="${sort}">
                    </div>
                    <div class="form-group">
                        <label>Status</label>
                        <select id="edit-plan-status" class="form-control">
                            <option value="active" ${status === 'active' ? 'selected' : ''}>Active</option>
                            <option value="inactive" ${status === 'inactive' ? 'selected' : ''}>Inactive</option>
                        </select>
                    </div>
                    <div style="margin-top:20px; display:flex; gap:10px;">
                        <button type="submit" class="btn-primary" style="flex:1;">Update Plan</button>
                        <button type="button" class="btn-sm" onclick="closeModal()">Cancel</button>
                    </div>
                </form>
            `);
        }

        async function savePlanUpdate(e, id) {
            e.preventDefault();
            const body = {
                name: document.getElementById('edit-plan-name').value,
                price: parseFloat(document.getElementById('edit-plan-price').value),
                billing_period: document.getElementById('edit-plan-period').value,
                max_staff_accounts: parseInt(document.getElementById('edit-plan-max-staff').value) || 0,
                sort_order: parseInt(document.getElementById('edit-plan-sort').value) || 0,
                status: document.getElementById('edit-plan-status').value,
            };
            const res = await apiFetch(`/plans/${id}`, 'PUT', body);
            if (res && res.success) {
                alert('Plan updated successfully!');
                closeModal();
                loadPlansView();
            } else {
                alert(res.message || 'Failed to update plan');
            }
        }

        async function togglePlanStatus(id) {
            const res = await apiFetch(`/plans/${id}/toggle-status`, 'POST');
            if (res && res.success) {
                loadPlansView();
            } else {
                alert(res.message || 'Failed to toggle status');
            }
        }

        // 7. REVENUE VIEW
        async function loadRevenueView() {
            const content = getContentContainer();
            const data = await apiFetch('/revenue');
            if (!data || !data.success) return;
            const r = data.data;

            content.innerHTML = `
                <div class="grid-4" style="grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));">
                    <div class="metric-card">
                        <div class="metric-title">Total Platform Revenue</div>
                        <div class="metric-value">₹${r.total_revenue.toLocaleString()}</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-title">Revenue This Month</div>
                        <div class="metric-value">₹${r.revenue_this_month.toLocaleString()}</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-title">Paid Subscriptions</div>
                        <div class="metric-value">${r.paid_subscriptions_count}</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-title">Failed Payments</div>
                        <div class="metric-value">${r.failed_payments_count || 0}</div>
                    </div>
                </div>
            `;
        }

        // 8. PAYMENT GATEWAY SETTINGS VIEW
        async function loadGatewayView() {
            const content = getContentContainer();
            content.innerHTML = '<div style="padding:20px; color:#64748b;">Loading gateway configuration...</div>';
            const res = await apiFetch('/settings/payment-gateway');
            if (!res || res.status !== 'success') return;
            const g = res.data;

            content.innerHTML = `
                <div class="card-table" style="padding:24px; max-width:650px;">
                    <h3 style="font-size:18px; font-weight:700; margin-bottom:16px;">Razorpay Gateway Settings</h3>
                    <div id="gw-alert" class="alert-error"></div>
                    <form onsubmit="saveGatewaySettings(event)">
                        <div class="form-group">
                            <label>Gateway Status</label>
                            <select id="gw-active" class="form-control">
                                <option value="1" ${g.active ? 'selected' : ''}>Enabled</option>
                                <option value="0" ${!g.active ? 'selected' : ''}>Disabled</option>
                            </select>
                        </div>
                        <div class="form-group">
                            <label>Environment Mode</label>
                            <select id="gw-mode" class="form-control">
                                <option value="test" ${g.mode === 'test' ? 'selected' : ''}>TEST Mode</option>
                                <option value="live" ${g.mode === 'live' ? 'selected' : ''}>LIVE Production Mode</option>
                            </select>
                        </div>
                        <div class="form-group">
                            <label>Razorpay Key ID</label>
                            <input type="text" id="gw-key-id" class="form-control" placeholder="rzp_test_xxxxxx" value="${g.key_id || ''}" required>
                        </div>
                        <div class="form-group">
                            <label>Razorpay Key Secret ${g.key_secret_configured ? '<span style="color:#16a34a; text-transform:none;">(Configured: ********)</span>' : '<span style="color:#dc2626; text-transform:none;">(Not Configured)</span>'}</label>
                            <input type="password" id="gw-key-secret" class="form-control" placeholder="Leave blank to keep existing key secret">
                        </div>
                        <div class="form-group">
                            <label>Razorpay Webhook Secret ${g.webhook_secret_configured ? '<span style="color:#16a34a; text-transform:none;">(Configured: ********)</span>' : '<span style="color:#64748b; text-transform:none;">(Optional)</span>'}</label>
                            <input type="password" id="gw-webhook-secret" class="form-control" placeholder="Leave blank to keep existing webhook secret">
                        </div>
                        <div class="form-group">
                            <label>Free Trial Period (Months)</label>
                            <input type="number" id="gw-trial" class="form-control" value="${g.trial_months || 1}" min="0" max="24" required>
                        </div>
                        <div style="display:flex; gap:12px; margin-top:24px;">
                            <button type="submit" class="btn-primary" style="flex:1;">Save Gateway Settings</button>
                            <button type="button" class="btn-sm" style="padding:12px 18px;" onclick="testGatewayConnection()">Test Connection</button>
                        </div>
                    </form>
                </div>
            `;
        }

        async function saveGatewaySettings(e) {
            e.preventDefault();
            const body = {
                key_id: document.getElementById('gw-key-id').value,
                mode: document.getElementById('gw-mode').value,
                currency: 'INR',
                active: document.getElementById('gw-active').value === '1',
                trial_months: parseInt(document.getElementById('gw-trial').value),
            };
            const sec = document.getElementById('gw-key-secret').value;
            const wh = document.getElementById('gw-webhook-secret').value;
            if (sec) body.key_secret = sec;
            if (wh) body.webhook_secret = wh;

            const res = await apiFetch('/settings/payment-gateway', 'POST', body);
            if (res && res.status === 'success') {
                alert('Razorpay Gateway Settings Saved Successfully!');
                loadGatewayView();
            } else {
                alert(res.message || 'Failed to save settings');
            }
        }

        async function testGatewayConnection() {
            const body = {
                key_id: document.getElementById('gw-key-id').value,
            };
            const sec = document.getElementById('gw-key-secret').value;
            if (sec) body.key_secret = sec;

            alert('Testing connection to Razorpay API...');
            const res = await apiFetch('/settings/payment-gateway/test', 'POST', body);
            if (res && res.success) {
                alert('SUCCESS: ' + res.message);
            } else {
                alert('FAILED: ' + (res.message || 'Authentication error'));
            }
        }

        // 9. SUPPORT VIEW
        async function loadSupportView(page = 1, search = '', status = '', type = '') {
            const content = getContentContainer();
            const data = await apiFetch(`/support?page=${page}&search=${encodeURIComponent(search)}&status=${status}&type=${type}`);
            if (!data || !data.success) return;
            const pageData = data.data;
            const tickets = pageData.data || [];

            content.innerHTML = `
                <div class="card-table" style="padding:24px; margin-bottom:24px; max-width:850px;">
                    <h3 style="font-size:18px; font-weight:700; margin-bottom:6px;">💬 Mobile App Support Contact Settings</h3>
                    <p style="font-size:13px; color:#64748b; margin-bottom:16px;">Configure official support email, helpline phone number, and working hours displayed in the Mobile App Settings dialog.</p>
                    <form onsubmit="saveSupportContactInfo(event)" style="display:flex; flex-direction:column; gap:14px;">
                        <div style="display:flex; gap:16px; flex-wrap:wrap;">
                            <div class="form-group" style="flex:1; min-width:240px;">
                                <label style="font-size:12px; font-weight:600; color:#475569;">Official Support Email</label>
                                <input type="email" id="support_email" class="form-control" required placeholder="support@mobileprofits.com">
                            </div>
                            <div class="form-group" style="flex:1; min-width:240px;">
                                <label style="font-size:12px; font-weight:600; color:#475569;">Support Helpline Number</label>
                                <input type="text" id="support_phone" class="form-control" required placeholder="+91 98765 43210">
                            </div>
                        </div>
                        <div class="form-group">
                            <label style="font-size:12px; font-weight:600; color:#475569;">Support Working Hours</label>
                            <input type="text" id="support_hours" class="form-control" required placeholder="Mon - Sat: 9:00 AM - 8:00 PM IST">
                        </div>
                        <div>
                            <button type="submit" class="btn-primary" style="padding:10px 24px; border-radius:8px; font-weight:600;">Save Support Contact Details</button>
                        </div>
                    </form>
                </div>

                <div class="card-table">
                    <div class="table-toolbar">
                        <div style="display:flex; gap:10px; flex:1; min-width:280px;">
                            <div class="search-box" style="flex:1;">
                                <input type="text" id="support-search-input" placeholder="Search subject, message, shop..." value="${search}" oninput="debounceSearch(() => loadSupportView(1, document.getElementById('support-search-input').value, '${status}', '${type}'))">
                            </div>
                        </div>
                        <div style="display:flex; gap:10px; flex-wrap:wrap; align-items:center;">
                            <select class="filter-select" onchange="loadSupportView(1, '${search}', this.value, '${type}')">
                                <option value="">Status: All</option>
                                <option value="open" ${status === 'open' ? 'selected' : ''}>Open</option>
                                <option value="in_progress" ${status === 'in_progress' ? 'selected' : ''}>In Progress</option>
                                <option value="resolved" ${status === 'resolved' ? 'selected' : ''}>Resolved</option>
                            </select>
                            <select class="filter-select" onchange="loadSupportView(1, '${search}', '${status}', this.value)">
                                <option value="">Type: All</option>
                                <option value="contact" ${type === 'contact' ? 'selected' : ''}>Contact</option>
                                <option value="problem" ${type === 'problem' ? 'selected' : ''}>Problem</option>
                                <option value="feedback" ${type === 'feedback' ? 'selected' : ''}>Feedback</option>
                            </select>
                            ${(search || status || type) ? `<button class="btn-sm" style="background:#e2e8f0; color:#334155;" onclick="loadSupportView(1, '', '', '')">Clear Filters</button>` : ''}
                        </div>
                    </div>
                    <div class="table-responsive">
                    <table>
                        <thead>
                            <tr>
                                <th>Type</th>
                                <th>Shop / Owner</th>
                                <th>Message</th>
                                <th>Date</th>
                                <th>Status</th>
                                <th>Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${tickets.length === 0 ? `<tr><td colspan="6" style="text-align:center; padding:30px; color:#94a3b8;">No support tickets found matching filter criteria.</td></tr>` : ''}
                            ${tickets.map(t => `
                                <tr>
                                    <td><span class="badge badge-trial">${t.type}</span></td>
                                    <td><strong>${t.shop ? t.shop.name : 'Unknown Shop'}</strong></td>
                                    <td>${t.message}</td>
                                    <td>${new Date(t.created_at).toLocaleDateString()}</td>
                                    <td><span class="badge ${t.status === 'resolved' ? 'badge-resolved' : 'badge-inactive'}">${t.status}</span></td>
                                    <td>
                                        ${t.status !== 'resolved' ? `<button class="btn-sm btn-success-sm" onclick="resolveTicket(${t.id})">Mark Resolved</button>` : '—'}
                                    </td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                    </div>
                    ${renderPagination(pageData, 'loadSupportView', search, status, type)}
                </div>
            `;

            loadSupportContactInfo();
        }

        async function resolveTicket(id) {
            const data = await apiFetch(`/support/${id}/status`, 'PUT', { status: 'resolved' });
            if (data.success) {
                loadSupportView();
            }
        }

        async function loadSupportContactInfo() {
            const res = await apiFetch('/support/contact-info');
            if (res && res.success && res.data) {
                const info = res.data;
                if (document.getElementById('support_email')) document.getElementById('support_email').value = info.support_email || '';
                if (document.getElementById('support_phone')) document.getElementById('support_phone').value = info.support_phone || '';
                if (document.getElementById('support_hours')) document.getElementById('support_hours').value = info.support_hours || '';
            }
        }

        async function saveSupportContactInfo(e) {
            e.preventDefault();
            const email = document.getElementById('support_email').value;
            const phone = document.getElementById('support_phone').value;
            const hours = document.getElementById('support_hours').value;

            const res = await apiFetch('/support/contact-info', 'POST', {
                support_email: email,
                support_phone: phone,
                support_hours: hours
            });

            if (res && res.success) {
                alert('Official Support Contact Details Saved Successfully!');
                loadSupportContactInfo();
            } else {
                alert('Failed to save support details: ' + (res.message || 'Error'));
            }
        }

        // 10. AUDIT LOGS VIEW
        async function loadAuditView(page = 1, search = '', action = '') {
            const content = getContentContainer();
            const data = await apiFetch(`/audit-logs?page=${page}&search=${encodeURIComponent(search)}&action=${action}`);
            if (!data || !data.success) return;
            const pageData = data.data;
            const logs = pageData.data || [];

            content.innerHTML = `
                <div class="card-table">
                    <div class="table-toolbar">
                        <div style="display:flex; gap:10px; flex:1; min-width:280px;">
                            <div class="search-box" style="flex:1;">
                                <input type="text" id="audit-search-input" placeholder="Search details, IP, admin name..." value="${search}" oninput="debounceSearch(() => loadAuditView(1, document.getElementById('audit-search-input').value, '${action}'))">
                            </div>
                        </div>
                        <div style="display:flex; gap:10px; flex-wrap:wrap; align-items:center;">
                            <select class="filter-select" onchange="loadAuditView(1, '${search}', this.value)">
                                <option value="">Action: All Actions</option>
                                <option value="ACTIVATE_SHOP" ${action === 'ACTIVATE_SHOP' ? 'selected' : ''}>Activate Shop</option>
                                <option value="DEACTIVATE_SHOP" ${action === 'DEACTIVATE_SHOP' ? 'selected' : ''}>Deactivate Shop</option>
                                <option value="UPDATE_SUBSCRIPTION" ${action === 'UPDATE_SUBSCRIPTION' ? 'selected' : ''}>Update Subscription</option>
                                <option value="update_payment_gateway_settings" ${action === 'update_payment_gateway_settings' ? 'selected' : ''}>Update Gateway</option>
                                <option value="UPDATE_SUPPORT_STATUS" ${action === 'UPDATE_SUPPORT_STATUS' ? 'selected' : ''}>Support Status</option>
                            </select>
                            ${(search || action) ? `<button class="btn-sm" style="background:#e2e8f0; color:#334155;" onclick="loadAuditView(1, '', '')">Clear Filters</button>` : ''}
                        </div>
                    </div>
                    <div class="table-responsive">
                    <table>
                        <thead>
                            <tr>
                                <th>Admin User</th>
                                <th>Action Taken</th>
                                <th>Action Details</th>
                                <th>IP Address</th>
                                <th>Timestamp</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${logs.length === 0 ? `<tr><td colspan="5" style="text-align:center; padding:30px; color:#94a3b8;">No audit logs found matching filter criteria.</td></tr>` : ''}
                            ${logs.map(l => `
                                <tr>
                                    <td><strong>${l.admin ? l.admin.name : 'Admin System'}</strong></td>
                                    <td><span class="badge badge-resolved">${l.action}</span></td>
                                    <td>${l.details || '—'}</td>
                                    <td>${l.ip_address || '—'}</td>
                                    <td>${new Date(l.created_at).toLocaleString()}</td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                    </div>
                    ${renderPagination(pageData, 'loadAuditView', search, action)}
                </div>
            `;
        }

        // 10.5 APP VERSION & FORCE UPDATE SETTINGS VIEW
        async function loadAppVersionView() {
            const content = getContentContainer();
            content.innerHTML = '<div style="padding:20px; color:#64748b;">Loading app version settings...</div>';
            const res = await apiFetch('/app-version');
            if (!res || !res.success) return;
            const v = res.data || {};

            content.innerHTML = `
                <div class="card-table" style="padding:24px; max-width:680px;">
                    <div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:16px;">
                        <div>
                            <h3 style="font-size:18px; font-weight:700; color:#0f172a;">📱 App Version & Force Update Configuration</h3>
                            <p style="font-size:13px; color:#64748b; margin-top:2px;">Set minimum required version and toggle force update screen for mobile app users.</p>
                        </div>
                    </div>
                    <div id="ver-alert" class="alert-error" style="display:none;"></div>
                    <div id="ver-success" style="display:none; background:#f0fdf4; border:1px solid #bbf7d0; color:#166534; padding:12px; border-radius:8px; margin-bottom:16px; font-size:14px; font-weight:500;"></div>
                    <form onsubmit="saveAppVersionSettings(event)">
                        <div style="display:grid; grid-template-columns:1fr 1fr; gap:16px;">
                            <div class="form-group">
                                <label style="font-weight:600;">Minimum Required Version</label>
                                <input type="text" id="ver-min" class="form-control" placeholder="e.g. 1.0.4" value="${v.min_version || '1.0.0'}" required>
                                <small style="color:#64748b; font-size:11px;">Apps below this version will be blocked with Force Update.</small>
                            </div>
                            <div class="form-group">
                                <label style="font-weight:600;">Latest Available Version</label>
                                <input type="text" id="ver-latest" class="form-control" placeholder="e.g. 1.0.5" value="${v.latest_version || '1.0.4'}" required>
                                <small style="color:#64748b; font-size:11px;">Current newest app release version.</small>
                            </div>
                        </div>

                        <div class="form-group" style="margin-top:12px;">
                            <label style="font-weight:600;">Force Update Mode</label>
                            <select id="ver-force" class="form-control" style="font-weight:600;">
                                <option value="1" ${v.force_update ? 'selected' : ''}>🚨 Enabled (Force Update Screen Active for outdated app versions)</option>
                                <option value="0" ${!v.force_update ? 'selected' : ''}>✅ Disabled (Normal operation for all versions)</option>
                            </select>
                        </div>

                        <div class="form-group" style="margin-top:12px;">
                            <label style="font-weight:600;">App Update / Download Link (Store URL or Direct APK)</label>
                            <input type="text" id="ver-url" class="form-control" placeholder="https://play.google.com/store/apps/details?id=com.repairehub" value="${v.update_url || ''}">
                            <small style="color:#64748b; font-size:11px;">Target link opened when user taps 'Update Now'.</small>
                        </div>

                        <div class="form-group" style="margin-top:12px;">
                            <label style="font-weight:600;">Update Screen Title</label>
                            <input type="text" id="ver-title" class="form-control" placeholder="Update Required" value="${v.update_title || 'Update Required'}">
                        </div>

                        <div class="form-group" style="margin-top:12px;">
                            <label style="font-weight:600;">Update Description / Release Notes</label>
                            <textarea id="ver-message" class="form-control" rows="3" placeholder="A critical update is available for Mobile Shop Profit. Please update your app to continue using all features smoothly.">${v.update_message || ''}</textarea>
                        </div>

                        <div style="margin-top:24px;">
                            <button type="submit" class="btn-primary" style="width:100%; padding:12px; font-weight:600;">Save Version Settings</button>
                        </div>
                    </form>
                </div>
            `;
        }

        async function saveAppVersionSettings(e) {
            e.preventDefault();
            const alertErr = document.getElementById('ver-alert');
            const alertSucc = document.getElementById('ver-success');
            alertErr.style.display = 'none';
            alertSucc.style.display = 'none';

            const body = {
                min_version: document.getElementById('ver-min').value.trim(),
                latest_version: document.getElementById('ver-latest').value.trim(),
                force_update: document.getElementById('ver-force').value,
                update_url: document.getElementById('ver-url').value.trim(),
                update_title: document.getElementById('ver-title').value.trim(),
                update_message: document.getElementById('ver-message').value.trim(),
            };

            const res = await apiFetch('/app-version', 'POST', body);
            if (res && res.success) {
                alertSucc.style.display = 'block';
                alertSucc.innerText = res.message || 'Settings updated successfully!';
                setTimeout(() => { alertSucc.style.display = 'none'; }, 4000);
            } else {
                alertErr.style.display = 'block';
                alertErr.innerText = res.message || 'Failed to update settings';
            }
        }

        // 11. WEBSITE & LEGAL PAGES CMS VIEW
        async function loadPagesView() {
            const content = getContentContainer();
            content.innerHTML = '<div style="padding:20px; color:#64748b;">Loading dynamic legal pages...</div>';
            const data = await apiFetch('/pages');
            if (!data || !data.success) return;
            const pages = data.data || [];

            content.innerHTML = `
                <div style="margin-bottom:20px; display:flex; justify-content:space-between; align-items:center;">
                    <div>
                        <h2 style="font-size:18px; font-weight:700; color:#0f172a;">Website & Legal Pages</h2>
                        <p style="font-size:13px; color:#64748b; margin-top:2px;">Manage Privacy Policy, Terms & Conditions, Refund Policy, and Account Deletion content live on your website and Mobile App.</p>
                    </div>
                </div>
                <div class="card-table">
                    <div class="table-responsive">
                    <table>
                        <thead>
                            <tr>
                                <th>Page Title</th>
                                <th>URL Slug</th>
                                <th>Status</th>
                                <th>Last Updated</th>
                                <th>Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${pages.length === 0 ? `<tr><td colspan="5" style="text-align:center; padding:30px; color:#94a3b8;">No dynamic pages found.</td></tr>` : ''}
                            ${pages.map(p => `
                                <tr>
                                    <td><strong>${p.title}</strong></td>
                                    <td><code style="background:#f1f5f9; padding:2px 6px; border-radius:4px; font-size:12px; color:#0284c7;">/${p.slug}</code></td>
                                    <td>
                                        <span class="badge ${p.status === 'published' ? 'badge-active' : 'badge-inactive'}">${p.status}</span>
                                    </td>
                                    <td>${new Date(p.updated_at).toLocaleString()}</td>
                                    <td>
                                        <button class="btn-sm" style="background:#2563eb; color:white; border:none;" onclick="openEditPageModal('${p.slug}')">✏️ Edit Page</button>
                                        <a href="/${p.slug}" target="_blank" class="btn-sm" style="text-decoration:none; margin-left:4px;">🌐 View Live</a>
                                    </td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                    </div>
                </div>
            `;
        }

        async function openEditPageModal(slug) {
            const data = await apiFetch(`/pages/${slug}`);
            if (!data || !data.success) {
                alert('Failed to load page content.');
                return;
            }
            const page = data.data;

            const html = `
                <form id="edit-page-form" onsubmit="handleSavePage(event, '${slug}')">
                    <div class="form-group">
                        <label>Page Title *</label>
                        <input type="text" id="page-edit-title" class="form-control" value="${(page.title || '').replace(/"/g, '&quot;')}" required>
                    </div>
                    <div class="form-group">
                        <label>Meta Description (SEO)</label>
                        <input type="text" id="page-edit-meta" class="form-control" value="${(page.meta_description || '').replace(/"/g, '&quot;')}">
                    </div>
                    <div class="form-group">
                        <label>Publication Status *</label>
                        <select id="page-edit-status" class="form-control">
                            <option value="published" ${page.status === 'published' ? 'selected' : ''}>Published (Live on Website & Mobile App)</option>
                            <option value="draft" ${page.status === 'draft' ? 'selected' : ''}>Draft (Hidden)</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label>Page HTML / Body Content *</label>
                        <textarea id="page-edit-content" class="form-control" rows="12" style="font-family:monospace; font-size:13px; line-height:1.5;" required>${(page.content || '')}</textarea>
                    </div>
                    <div style="display:flex; justify-content:flex-end; gap:10px; margin-top:20px;">
                        <button type="button" class="btn-sm" onclick="closeModal()">Cancel</button>
                        <button type="submit" class="btn-primary" style="width:auto; padding:8px 20px;">Save & Publish Changes</button>
                    </div>
                </form>
            `;
            openModal(`Edit ${page.title} (/${slug})`, html);
        }

        async function handleSavePage(e, slug) {
            e.preventDefault();
            const title = document.getElementById('page-edit-title').value;
            const meta_description = document.getElementById('page-edit-meta').value;
            const status = document.getElementById('page-edit-status').value;
            const content = document.getElementById('page-edit-content').value;

            const res = await apiFetch(`/pages/${slug}`, 'PUT', { title, meta_description, status, content });
            if (res && res.success) {
                closeModal();
                alert('Page updated and published successfully! Live website and Flutter app updated.');
                loadPagesView();
            } else {
                alert(res.message || 'Error updating page.');
            }
        }

        // 12. SALES & INVOICES VIEW
        async function loadSalesView(page = 1, search = '', shopId = '', status = '', dateFrom = '', dateTo = '') {
            const content = getContentContainer();
            content.innerHTML = '<div style="padding:20px; color:#64748b;">Loading sales records...</div>';

            const query = `/sales?page=${page}&search=${encodeURIComponent(search)}&shop_id=${shopId}&payment_status=${status}&date_from=${dateFrom}&date_to=${dateTo}`;
            const res = await apiFetch(query);
            if (!res || !res.success) return;

            const pageData = res.data;
            const sales = pageData.data || [];
            const sum = pageData.summary || { total_sales_amount: 0, total_paid_amount: 0, total_due_amount: 0, total_invoices_count: 0 };
            const shopsOptions = await getShopsDropdownOptions(shopId);

            content.innerHTML = `
                <div class="grid-4" style="grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));">
                    <div class="metric-card">
                        <div class="metric-title">Total Invoices</div>
                        <div class="metric-value">${sum.total_invoices_count}</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-title">Gross Sales Amount</div>
                        <div class="metric-value">₹${sum.total_sales_amount.toLocaleString()}</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-title">Total Paid Amount</div>
                        <div class="metric-value" style="color:#16a34a;">₹${sum.total_paid_amount.toLocaleString()}</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-title">Outstanding Amount Due</div>
                        <div class="metric-value" style="color:#dc2626;">₹${sum.total_due_amount.toLocaleString()}</div>
                    </div>
                </div>

                <div class="card-table">
                    <div class="table-toolbar">
                        <div style="display:flex; gap:10px; flex:1; min-width:280px;">
                            <div class="search-box" style="flex:1;">
                                <input type="text" id="sales-search-input" placeholder="Search invoice #, customer, mobile, shop..." value="${search}" oninput="debounceSearch(() => loadSalesView(1, document.getElementById('sales-search-input').value, '${shopId}', '${status}', '${dateFrom}', '${dateTo}'))">
                            </div>
                        </div>
                        <div style="display:flex; gap:10px; flex-wrap:wrap; align-items:center;">
                            <select class="filter-select" onchange="loadSalesView(1, '${search}', this.value, '${status}', '${dateFrom}', '${dateTo}')">
                                ${shopsOptions}
                            </select>
                            <select class="filter-select" onchange="loadSalesView(1, '${search}', '${shopId}', this.value, '${dateFrom}', '${dateTo}')">
                                <option value="">Payment Status: All</option>
                                <option value="paid" ${status === 'paid' ? 'selected' : ''}>Paid</option>
                                <option value="partially_paid" ${status === 'partially_paid' ? 'selected' : ''}>Partially Paid</option>
                                <option value="due" ${status === 'due' ? 'selected' : ''}>Due / Unpaid</option>
                            </select>
                            <input type="date" class="filter-select" value="${dateFrom}" title="From Date" onchange="loadSalesView(1, '${search}', '${shopId}', '${status}', this.value, '${dateTo}')">
                            <input type="date" class="filter-select" value="${dateTo}" title="To Date" onchange="loadSalesView(1, '${search}', '${shopId}', '${status}', '${dateFrom}', this.value)">
                            ${(search || shopId || status || dateFrom || dateTo) ? `<button class="btn-sm" style="background:#e2e8f0; color:#334155;" onclick="loadSalesView(1, '', '', '', '', '')">Clear Filters</button>` : ''}
                        </div>
                    </div>
                    <div class="table-responsive">
                    <table>
                        <thead>
                            <tr>
                                <th>Invoice #</th>
                                <th>Shop Name</th>
                                <th>Customer</th>
                                <th>Sale Date</th>
                                <th>Grand Total</th>
                                <th>Paid</th>
                                <th>Due</th>
                                <th>Payment Status</th>
                                <th>Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${sales.length === 0 ? `<tr><td colspan="9" style="text-align:center; padding:30px; color:#94a3b8;">No sales records found matching criteria.</td></tr>` : ''}
                            ${sales.map(s => {
                                const stBadge = s.payment_status === 'paid' ? 'badge-active' : (s.payment_status === 'partially_paid' ? 'badge-trial' : 'badge-inactive');
                                const sCustName = s.customer ? s.customer.name : (s.customer_name || 'Walk-in Customer');
                                const sCustMob = s.customer ? (s.customer.mobile || s.customer.phone || '') : (s.customer_mobile || '');
                                return `
                                <tr>
                                    <td><strong><code style="color:#0284c7;">${s.invoice_number || 'INV-' + s.id}</code></strong></td>
                                    <td>${s.shop ? s.shop.name : 'Shop #' + s.shop_id}</td>
                                    <td><strong>${sCustName}</strong>${sCustMob ? `<br><span style="font-size:12px; color:#64748b;">📞 ${sCustMob}</span>` : ''}</td>
                                    <td>${new Date(s.sale_date || s.created_at).toLocaleDateString()}</td>
                                    <td><strong>₹${parseFloat(s.grand_total).toFixed(2)}</strong></td>
                                    <td style="color:#16a34a;">₹${parseFloat(s.amount_paid).toFixed(2)}</td>
                                    <td style="color:${s.amount_due > 0 ? '#dc2626' : '#64748b'};">₹${parseFloat(s.amount_due).toFixed(2)}</td>
                                    <td><span class="badge ${stBadge}">${(s.payment_status || 'due').replace('_', ' ').toUpperCase()}</span></td>
                                    <td><button class="btn-sm" onclick="openSaleDetails(${s.id})">Invoice Details</button></td>
                                </tr>
                                `;
                            }).join('')}
                        </tbody>
                    </table>
                    </div>
                    ${renderPagination(pageData, 'loadSalesView', search, shopId, status, dateFrom, dateTo)}
                </div>
            `;
        }

        async function openSaleDetails(id) {
            const res = await apiFetch(`/sales/${id}`);
            if (!res || !res.success) return;
            const s = res.data;
            const sCustName = s.customer ? s.customer.name : (s.customer_name || 'Walk-in Customer / N/A');
            const sCustMob = s.customer ? (s.customer.mobile || s.customer.phone || '') : (s.customer_mobile || 'N/A');

            openModal(`Sale Invoice — ${s.invoice_number || 'INV-' + s.id}`, `
                <div style="font-size:13px; line-height:1.6;">
                    <div style="display:flex; justify-content:space-between; margin-bottom:14px; background:#f8fafc; padding:12px; border-radius:8px;">
                        <div>
                            <strong>Shop:</strong> ${s.shop ? s.shop.name : 'Shop #' + s.shop_id}<br>
                            <strong>Customer:</strong> ${sCustName} (${sCustMob})
                        </div>
                        <div style="text-align:right;">
                            <strong>Invoice Date:</strong> ${new Date(s.sale_date || s.created_at).toLocaleDateString()}<br>
                            <strong>Status:</strong> <span class="badge ${s.payment_status === 'paid' ? 'badge-active' : 'badge-trial'}">${(s.payment_status || '').toUpperCase()}</span>
                        </div>
                    </div>

                    <h4 style="font-size:12px; font-weight:700; text-transform:uppercase; color:#475569; margin-bottom:8px;">Line Items Purchased</h4>
                    <table style="width:100%; border-collapse:collapse; margin-bottom:14px;">
                        <thead>
                            <tr style="background:#f1f5f9;">
                                <th style="padding:6px; font-size:11px;">Item Description</th>
                                <th style="padding:6px; font-size:11px;">Qty</th>
                                <th style="padding:6px; font-size:11px;">Unit Price</th>
                                <th style="padding:6px; font-size:11px; text-align:right;">Total</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${(s.items || []).map(item => `
                                <tr>
                                    <td style="padding:6px; border-bottom:1px solid #e2e8f0;">${item.item_name}</td>
                                    <td style="padding:6px; border-bottom:1px solid #e2e8f0;">${item.quantity}</td>
                                    <td style="padding:6px; border-bottom:1px solid #e2e8f0;">₹${parseFloat(item.unit_price).toFixed(2)}</td>
                                    <td style="padding:6px; border-bottom:1px solid #e2e8f0; text-align:right;"><strong>₹${parseFloat(item.total_price).toFixed(2)}</strong></td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>

                    <div style="display:flex; justify-content:flex-end; gap:20px; font-size:14px; margin-top:10px;">
                        <div>Subtotal: <strong>₹${parseFloat(s.subtotal).toFixed(2)}</strong></div>
                        <div>Discount: <strong>-₹${parseFloat(s.discount || 0).toFixed(2)}</strong></div>
                        <div>Grand Total: <strong style="color:#2563eb; font-size:16px;">₹${parseFloat(s.grand_total).toFixed(2)}</strong></div>
                    </div>
                </div>
            `);
        }

        // 13. REPAIRS VIEW
        async function loadRepairsView(page = 1, search = '', shopId = '', status = '', dateFrom = '', dateTo = '') {
            const content = getContentContainer();
            content.innerHTML = '<div style="padding:20px; color:#64748b;">Loading repair job cards...</div>';

            const query = `/repairs?page=${page}&search=${encodeURIComponent(search)}&shop_id=${shopId}&status=${status}&date_from=${dateFrom}&date_to=${dateTo}`;
            const res = await apiFetch(query);
            if (!res || !res.success) return;

            const pageData = res.data;
            const repairs = pageData.data || [];
            const sum = pageData.summary || { total_count: 0, pending_count: 0, in_progress_count: 0, completed_count: 0, total_cost: 0, total_paid: 0 };
            const shopsOptions = await getShopsDropdownOptions(shopId);

            content.innerHTML = `
                <div class="grid-4" style="grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));">
                    <div class="metric-card">
                        <div class="metric-title">Total Repair Jobs</div>
                        <div class="metric-value">${sum.total_count}</div>
                        <div class="metric-sub">${sum.pending_count} Pending | ${sum.in_progress_count} In Progress</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-title">Completed & Delivered</div>
                        <div class="metric-value" style="color:#16a34a;">${sum.completed_count}</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-title">Total Repair Cost</div>
                        <div class="metric-value">₹${sum.total_cost.toLocaleString()}</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-title">Total Amount Paid</div>
                        <div class="metric-value" style="color:#10b981;">₹${sum.total_paid.toLocaleString()}</div>
                    </div>
                </div>

                <div class="card-table">
                    <div class="table-toolbar">
                        <div style="display:flex; gap:10px; flex:1; min-width:280px;">
                            <div class="search-box" style="flex:1;">
                                <input type="text" id="repairs-search-input" placeholder="Search job #, problem, device, customer, shop..." value="${search}" oninput="debounceSearch(() => loadRepairsView(1, document.getElementById('repairs-search-input').value, '${shopId}', '${status}', '${dateFrom}', '${dateTo}'))">
                            </div>
                        </div>
                        <div style="display:flex; gap:10px; flex-wrap:wrap; align-items:center;">
                            <select class="filter-select" onchange="loadRepairsView(1, '${search}', this.value, '${status}', '${dateFrom}', '${dateTo}')">
                                ${shopsOptions}
                            </select>
                            <select class="filter-select" onchange="loadRepairsView(1, '${search}', '${shopId}', this.value, '${dateFrom}', '${dateTo}')">
                                <option value="">Status: All</option>
                                <option value="received" ${status === 'received' ? 'selected' : ''}>Received</option>
                                <option value="diagnosing" ${status === 'diagnosing' ? 'selected' : ''}>Diagnosing</option>
                                <option value="repairing" ${status === 'repairing' ? 'selected' : ''}>Repairing</option>
                                <option value="ready" ${status === 'ready' ? 'selected' : ''}>Ready for Pickup</option>
                                <option value="delivered" ${status === 'delivered' ? 'selected' : ''}>Delivered</option>
                                <option value="cancelled" ${status === 'cancelled' ? 'selected' : ''}>Cancelled</option>
                            </select>
                            <input type="date" class="filter-select" value="${dateFrom}" title="From Date" onchange="loadRepairsView(1, '${search}', '${shopId}', '${status}', this.value, '${dateTo}')">
                            <input type="date" class="filter-select" value="${dateTo}" title="To Date" onchange="loadRepairsView(1, '${search}', '${shopId}', '${status}', '${dateFrom}', this.value)">
                            ${(search || shopId || status || dateFrom || dateTo) ? `<button class="btn-sm" style="background:#e2e8f0; color:#334155;" onclick="loadRepairsView(1, '', '', '', '', '')">Clear Filters</button>` : ''}
                        </div>
                    </div>
                    <div class="table-responsive">
                    <table>
                        <thead>
                            <tr>
                                <th>Job #</th>
                                <th>Shop Name</th>
                                <th>Customer & Device</th>
                                <th>Problem Description</th>
                                <th>Received Date</th>
                                <th>Cost</th>
                                <th>Paid</th>
                                <th>Status</th>
                                <th>Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${repairs.length === 0 ? `<tr><td colspan="9" style="text-align:center; padding:30px; color:#94a3b8;">No repair jobs found matching criteria.</td></tr>` : ''}
                            ${repairs.map(r => {
                                const custName = r.customer ? r.customer.name : (r.customer_name || 'Walk-in Customer / N/A');
                                const custMobile = r.customer ? (r.customer.mobile || r.customer.phone || '') : (r.customer_mobile || '');
                                const devBrand = r.device ? (r.device.brand || '') : '';
                                const devModel = r.device ? (r.device.model || '') : (r.device_model || '');
                                const devInfo = (devBrand + ' ' + devModel).trim() || 'N/A';
                                const costVal = parseFloat(r.final_cost > 0 ? r.final_cost : r.estimated_cost);
                                const isDelivered = r.repair_status === 'delivered' || r.repair_status === 'ready';
                                return `
                                <tr>
                                    <td><strong><code style="color:#d97706;">${r.job_number || 'JOB-' + r.id}</code></strong></td>
                                    <td>${r.shop ? r.shop.name : 'Shop #' + r.shop_id}</td>
                                    <td><strong>${custName}</strong>${custMobile ? `<br><span style="font-size:11px; color:#64748b;">📞 ${custMobile}</span>` : ''}<br><span style="font-size:11px; color:#2563eb;">📱 ${devInfo}</span></td>
                                    <td>${r.problem_description || '—'}</td>
                                    <td>${new Date(r.date_received || r.created_at).toLocaleDateString()}</td>
                                    <td><strong>₹${costVal.toFixed(2)}</strong></td>
                                    <td style="color:#16a34a;">₹${parseFloat(r.amount_paid).toFixed(2)}</td>
                                    <td><span class="badge ${isDelivered ? 'badge-active' : 'badge-trial'}">${(r.repair_status || '').toUpperCase()}</span></td>
                                    <td><button class="btn-sm" onclick="openRepairDetails(${r.id})">Job Details</button></td>
                                </tr>
                                `;
                            }).join('')}
                        </tbody>
                    </table>
                    </div>
                    ${renderPagination(pageData, 'loadRepairsView', search, shopId, status, dateFrom, dateTo)}
                </div>
            `;
        }

        async function openRepairDetails(id) {
            const res = await apiFetch(`/repairs/${id}`);
            if (!res || !res.success) return;
            const r = res.data;

            const costVal = parseFloat(r.final_cost > 0 ? r.final_cost : r.estimated_cost);
            const amountPaid = parseFloat(r.amount_paid || 0);
            const dueAmount = Math.max(0, costVal - amountPaid);
            const custName = r.customer ? r.customer.name : (r.customer_name || 'Walk-in Customer / N/A');
            const custMobile = r.customer ? (r.customer.mobile || r.customer.phone || '') : (r.customer_mobile || '');
            const custAltMobile = r.customer && r.customer.alternate_mobile ? r.customer.alternate_mobile : '';
            const custEmail = r.customer && r.customer.email ? r.customer.email : '';
            const custAddress = r.customer && (r.customer.address || r.customer.city) ? [r.customer.address, r.customer.city].filter(Boolean).join(', ') : '';

            const devBrand = r.device ? (r.device.brand || '') : '';
            const devModel = r.device ? (r.device.model || '') : (r.device_model || '');
            const devText = (devBrand + ' ' + devModel).trim() || 'N/A';
            const devColor = r.device && r.device.color ? r.device.color : '';
            const devImei = r.device ? (r.device.imei_1 || r.device.imei_2 || r.device.serial_number || '') : '';

            const techName = r.technician ? r.technician.name : 'Unassigned';
            const techPhone = r.technician && r.technician.mobile ? r.technician.mobile : '';

            openModal(`Repair Job Card — ${r.job_number || 'JOB-' + r.id}`, `
                <div style="font-size:13px; line-height:1.6;">
                    <div style="display:grid; grid-template-columns:1fr 1fr; gap:12px; margin-bottom:14px; background:#f8fafc; padding:14px; border-radius:10px; border:1px solid #e2e8f0;">
                        <div>
                            <div style="font-size:11px; font-weight:700; text-transform:uppercase; color:#64748b; margin-bottom:4px;">Customer & Device Details</div>
                            <p style="margin-bottom:2px;"><strong>👤 Customer:</strong> <span style="font-weight:600; color:#0f172a;">${custName}</span></p>
                            <p style="margin-bottom:2px;"><strong>📞 Phone:</strong> ${custMobile ? `<a href="tel:${custMobile}" style="color:#2563eb; text-decoration:none;">${custMobile}</a>` : 'N/A'}${custAltMobile ? ` / ${custAltMobile}` : ''}</p>
                            ${custEmail ? `<p style="margin-bottom:2px;"><strong>✉️ Email:</strong> ${custEmail}</p>` : ''}
                            ${custAddress ? `<p style="margin-bottom:2px;"><strong>📍 Address:</strong> ${custAddress}</p>` : ''}
                            <hr style="margin:6px 0; border:0; border-top:1px dashed #cbd5e1;">
                            <p style="margin-bottom:2px;"><strong>📱 Device:</strong> <span style="color:#2563eb; font-weight:600;">${devText}</span>${devColor ? ` (${devColor})` : ''}</p>
                            ${devImei ? `<p style="margin-bottom:2px;"><strong>🔢 Identifier:</strong> <code>${devImei}</code></p>` : ''}
                        </div>
                        <div>
                            <div style="font-size:11px; font-weight:700; text-transform:uppercase; color:#64748b; margin-bottom:4px;">Shop & Status Details</div>
                            <p style="margin-bottom:2px;"><strong>🏪 Shop:</strong> ${r.shop ? r.shop.name : 'Shop #' + r.shop_id}</p>
                            <p style="margin-bottom:2px;"><strong>📅 Received Date:</strong> ${new Date(r.date_received || r.created_at).toLocaleDateString()}</p>
                            ${r.expected_delivery_date ? `<p style="margin-bottom:2px;"><strong>🚚 Expected:</strong> ${new Date(r.expected_delivery_date).toLocaleDateString()}</p>` : ''}
                            ${r.delivered_date ? `<p style="margin-bottom:2px;"><strong>✅ Delivered:</strong> ${new Date(r.delivered_date).toLocaleString()}</p>` : ''}
                            <p style="margin-bottom:2px;"><strong>🏷️ Status:</strong> <span class="badge ${(['delivered', 'ready'].includes(r.repair_status)) ? 'badge-active' : 'badge-trial'}">${(r.repair_status || '').toUpperCase()}</span></p>
                            <p style="margin-bottom:2px;"><strong>🧰 Technician:</strong> ${techName}${techPhone ? ` (${techPhone})` : ''}</p>
                        </div>
                    </div>

                    <div style="background:#fff; border:1px solid #e2e8f0; border-radius:8px; padding:12px; margin-bottom:12px;">
                        <p style="margin-bottom:6px;"><strong>Problem Description:</strong> ${r.problem_description || 'None'}</p>
                        ${r.pin_passcode ? `<p style="margin-bottom:6px;"><strong>Device Passcode / PIN:</strong> <code style="background:#f1f5f9; padding:2px 6px; border-radius:4px; font-weight:700;">${r.pin_passcode}</code></p>` : ''}
                        ${r.condition_notes ? `<p style="margin-bottom:6px;"><strong>Condition Notes:</strong> ${r.condition_notes}</p>` : ''}
                        ${r.accessories_received ? `<p style="margin-bottom:6px;"><strong>Accessories Received:</strong> ${Array.isArray(r.accessories_received) ? r.accessories_received.join(', ') : r.accessories_received}</p>` : ''}
                        ${r.customer_notes ? `<p style="margin-bottom:6px;"><strong>Customer Notes:</strong> ${r.customer_notes}</p>` : ''}
                        ${r.internal_notes ? `<p style="margin-bottom:6px;"><strong>Internal Notes:</strong> ${r.internal_notes}</p>` : ''}
                    </div>

                    <h4 style="font-size:12px; font-weight:700; text-transform:uppercase; color:#475569; margin-bottom:6px;">Spare Parts Used</h4>
                    <table style="width:100%; border-collapse:collapse; margin-bottom:12px;">
                        <thead>
                            <tr style="background:#f1f5f9;"><th style="padding:6px; text-align:left;">Part Name</th><th style="padding:6px; text-align:center;">Qty</th><th style="padding:6px; text-align:right;">Price</th></tr>
                        </thead>
                        <tbody>
                            ${(r.parts || []).length === 0 ? '<tr><td colspan="3" style="padding:8px; text-align:center; color:#94a3b8;">No spare parts logged for this job.</td></tr>' : ''}
                            ${(r.parts || []).map(p => `
                                <tr>
                                    <td style="padding:6px; border-bottom:1px solid #e2e8f0;">${p.part_name}</td>
                                    <td style="padding:6px; border-bottom:1px solid #e2e8f0; text-align:center;">${p.quantity}</td>
                                    <td style="padding:6px; border-bottom:1px solid #e2e8f0; text-align:right;">₹${parseFloat(p.selling_price || p.price || p.cost_price || 0).toFixed(2)}</td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>

                    <div style="display:flex; justify-content:flex-end; gap:16px; font-size:13px; background:#f8fafc; padding:12px; border-radius:8px;">
                        <div>Labor Cost: <strong>₹${parseFloat(r.labour_cost || 0).toFixed(2)}</strong></div>
                        <div>Total Cost: <strong style="color:#d97706; font-size:15px;">₹${costVal.toFixed(2)}</strong></div>
                        <div>Paid: <strong style="color:#16a34a; font-size:15px;">₹${amountPaid.toFixed(2)}</strong></div>
                        <div>Due Balance: <strong style="color:${dueAmount > 0 ? '#dc2626' : '#16a34a'}; font-size:15px;">₹${dueAmount.toFixed(2)}</strong></div>
                    </div>
                </div>
            `);
        }

        // 14. CUSTOMERS DIRECTORY VIEW
        async function loadCustomersView(page = 1, search = '', shopId = '') {
            const content = getContentContainer();
            content.innerHTML = '<div style="padding:20px; color:#64748b;">Loading customer directory...</div>';

            const query = `/customers?page=${page}&search=${encodeURIComponent(search)}&shop_id=${shopId}`;
            const res = await apiFetch(query);
            if (!res || !res.success) return;

            const pageData = res.data;
            const customers = pageData.data || [];
            const shopsOptions = await getShopsDropdownOptions(shopId);

            content.innerHTML = `
                <div class="card-table">
                    <div class="table-toolbar">
                        <div style="display:flex; gap:10px; flex:1; min-width:280px;">
                            <div class="search-box" style="flex:1;">
                                <input type="text" id="customers-search-input" placeholder="Search customer name, mobile, email, shop..." value="${search}" oninput="debounceSearch(() => loadCustomersView(1, document.getElementById('customers-search-input').value, '${shopId}'))">
                            </div>
                        </div>
                        <div style="display:flex; gap:10px; flex-wrap:wrap; align-items:center;">
                            <select class="filter-select" onchange="loadCustomersView(1, '${search}', this.value)">
                                ${shopsOptions}
                            </select>
                            ${(search || shopId) ? `<button class="btn-sm" style="background:#e2e8f0; color:#334155;" onclick="loadCustomersView(1, '', '')">Clear Filters</button>` : ''}
                        </div>
                    </div>
                    <div class="table-responsive">
                    <table>
                        <thead>
                            <tr>
                                <th>Customer Name</th>
                                <th>Mobile Number</th>
                                <th>Email / City</th>
                                <th>Associated Shop</th>
                                <th>Sales Invoices</th>
                                <th>Repairs Logged</th>
                                <th>Total Spent</th>
                                <th>Date Added</th>
                                <th>Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${customers.length === 0 ? `<tr><td colspan="9" style="text-align:center; padding:30px; color:#94a3b8;">No customer records found matching criteria.</td></tr>` : ''}
                            ${customers.map(c => `
                                <tr>
                                    <td><strong>${c.name}</strong></td>
                                    <td>${c.mobile} ${c.alternate_mobile ? '<br><span style="font-size:11px; color:#64748b;">Alt: ' + c.alternate_mobile + '</span>' : ''}</td>
                                    <td>${c.email || '—'}<br><span style="font-size:11px; color:#64748b;">${c.city || ''}</span></td>
                                    <td>${c.shop ? c.shop.name : 'Shop #' + c.shop_id}</td>
                                    <td>${c.sales_count || 0}</td>
                                    <td>${c.repairs_count || 0}</td>
                                    <td><strong style="color:#2563eb;">₹${parseFloat(c.total_spent || 0).toFixed(2)}</strong></td>
                                    <td>${new Date(c.created_at).toLocaleDateString()}</td>
                                    <td><button class="btn-sm" onclick="openCustomerDetails(${c.id})">Customer Profile</button></td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                    </div>
                    ${renderPagination(pageData, 'loadCustomersView', search, shopId)}
                </div>
            `;
        }

        async function openCustomerDetails(id) {
            const res = await apiFetch(`/customers/${id}`);
            if (!res || !res.success) return;
            const c = res.data;

            openModal(`Customer Profile — ${c.name}`, `
                <div style="font-size:13px; line-height:1.6;">
                    <p><strong>Shop:</strong> ${c.shop ? c.shop.name : 'Shop #' + c.shop_id}</p>
                    <p><strong>Mobile:</strong> ${c.mobile} ${c.alternate_mobile ? ' | Alt: ' + c.alternate_mobile : ''}</p>
                    <p><strong>Email:</strong> ${c.email || 'N/A'} | <strong>City:</strong> ${c.city || 'N/A'}</p>
                    <p><strong>Total Lifetime Spent:</strong> <strong style="color:#16a34a; font-size:15px;">₹${parseFloat(c.total_spent || 0).toFixed(2)}</strong></p>
                    <hr style="margin:12px 0; border:0; border-top:1px solid #e2e8f0;">

                    <h4 style="font-size:13px; font-weight:700; margin-bottom:6px;">Registered Customer Devices (${(c.devices || []).length})</h4>
                    <ul style="list-style:none; padding:0; margin-bottom:14px;">
                        ${(c.devices || []).length === 0 ? '<li style="color:#94a3b8;">No devices registered.</li>' : ''}
                        ${(c.devices || []).map(d => `
                            <li style="background:#f8fafc; padding:6px 10px; border-radius:6px; margin-bottom:4px;">
                                📱 <strong>${d.brand} ${d.model}</strong> ${d.imei_serial ? `(IMEI/Serial: ${d.imei_serial})` : ''}
                            </li>
                        `).join('')}
                    </ul>

                    <h4 style="font-size:13px; font-weight:700; margin-bottom:6px;">Sales History (${(c.sales || []).length})</h4>
                    <ul style="list-style:none; padding:0; margin-bottom:14px;">
                        ${(c.sales || []).length === 0 ? '<li style="color:#94a3b8;">No sales history.</li>' : ''}
                        ${(c.sales || []).map(s => `
                            <li style="padding:6px; border-bottom:1px solid #e2e8f0; display:flex; justify-content:space-between;">
                                <span>Invoice #${s.invoice_number || s.id} — ${new Date(s.sale_date || s.created_at).toLocaleDateString()}</span>
                                <strong>₹${parseFloat(s.grand_total).toFixed(2)} (${s.payment_status})</strong>
                            </li>
                        `).join('')}
                    </ul>
                </div>
            `);
        }

        // 15. INVENTORY STOCK VIEW
        async function loadInventoryView(page = 1, search = '', shopId = '', lowStock = false, outOfStock = false) {
            const content = getContentContainer();
            content.innerHTML = '<div style="padding:20px; color:#64748b;">Loading inventory stock...</div>';

            const query = `/inventory?page=${page}&search=${encodeURIComponent(search)}&shop_id=${shopId}&low_stock=${lowStock ? 1 : 0}&out_of_stock=${outOfStock ? 1 : 0}`;
            const res = await apiFetch(query);
            if (!res || !res.success) return;

            const pageData = res.data;
            const items = pageData.data || [];
            const sum = pageData.summary || { total_items_count: 0, low_stock_count: 0, out_of_stock_count: 0, total_stock_value: 0, total_selling_value: 0 };
            const shopsOptions = await getShopsDropdownOptions(shopId);

            content.innerHTML = `
                <div class="grid-4" style="grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));">
                    <div class="metric-card">
                        <div class="metric-title">Total Stock Items</div>
                        <div class="metric-value">${sum.total_items_count}</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-title">Stock Purchase Value</div>
                        <div class="metric-value">₹${sum.total_stock_value.toLocaleString()}</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-title">Stock Selling Value</div>
                        <div class="metric-value" style="color:#10b981;">₹${sum.total_selling_value.toLocaleString()}</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-title">Low / Out of Stock</div>
                        <div class="metric-value" style="color:#dc2626;">${sum.low_stock_count + sum.out_of_stock_count}</div>
                        <div class="metric-sub">${sum.low_stock_count} Low Stock | ${sum.out_of_stock_count} Out of Stock</div>
                    </div>
                </div>

                <div class="card-table">
                    <div class="table-toolbar">
                        <div style="display:flex; gap:10px; flex:1; min-width:280px;">
                            <div class="search-box" style="flex:1;">
                                <input type="text" id="inventory-search-input" placeholder="Search item name, SKU, brand, model, shop..." value="${search}" oninput="debounceSearch(() => loadInventoryView(1, document.getElementById('inventory-search-input').value, '${shopId}', ${lowStock}, ${outOfStock}))">
                            </div>
                        </div>
                        <div style="display:flex; gap:10px; flex-wrap:wrap; align-items:center;">
                            <select class="filter-select" onchange="loadInventoryView(1, '${search}', this.value, ${lowStock}, ${outOfStock})">
                                ${shopsOptions}
                            </select>
                            <label style="font-size:13px; display:flex; align-items:center; gap:6px; cursor:pointer;">
                                <input type="checkbox" ${lowStock ? 'checked' : ''} onchange="loadInventoryView(1, '${search}', '${shopId}', this.checked, ${outOfStock})"> Low Stock Only
                            </label>
                            <label style="font-size:13px; display:flex; align-items:center; gap:6px; cursor:pointer;">
                                <input type="checkbox" ${outOfStock ? 'checked' : ''} onchange="loadInventoryView(1, '${search}', '${shopId}', ${lowStock}, this.checked)"> Out of Stock Only
                            </label>
                            ${(search || shopId || lowStock || outOfStock) ? `<button class="btn-sm" style="background:#e2e8f0; color:#334155;" onclick="loadInventoryView(1, '', '', false, false)">Clear Filters</button>` : ''}
                        </div>
                    </div>
                    <div class="table-responsive">
                    <table>
                        <thead>
                            <tr>
                                <th>Item Name</th>
                                <th>Shop Name</th>
                                <th>SKU / Category</th>
                                <th>Brand & Model</th>
                                <th>Current Stock</th>
                                <th>Min Stock</th>
                                <th>Cost Price</th>
                                <th>Selling Price</th>
                                <th>Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${items.length === 0 ? `<tr><td colspan="9" style="text-align:center; padding:30px; color:#94a3b8;">No inventory items found matching criteria.</td></tr>` : ''}
                            ${items.map(i => {
                                const isLow = i.current_stock <= i.minimum_stock && i.current_stock > 0;
                                const isOut = i.current_stock <= 0;
                                const stBadge = isOut ? 'badge-inactive' : (isLow ? 'badge-trial' : 'badge-active');
                                return `
                                <tr>
                                    <td><strong>${i.name}</strong></td>
                                    <td>${i.shop ? i.shop.name : 'Shop #' + i.shop_id}</td>
                                    <td><code style="font-size:12px;">${i.sku || '—'}</code><br><span style="font-size:11px; color:#64748b;">${i.category || 'General'}</span></td>
                                    <td>${i.brand || '—'} ${i.model || ''}</td>
                                    <td><span class="badge ${stBadge}">${i.current_stock} ${i.unit || 'pcs'}</span></td>
                                    <td>${i.minimum_stock || 0}</td>
                                    <td>₹${parseFloat(i.purchase_price).toFixed(2)}</td>
                                    <td><strong>₹${parseFloat(i.selling_price).toFixed(2)}</strong></td>
                                    <td><button class="btn-sm" onclick="openInventoryDetails(${i.id})">Details</button></td>
                                </tr>
                                `;
                            }).join('')}
                        </tbody>
                    </table>
                    </div>
                    ${renderPagination(pageData, 'loadInventoryView', search, shopId, lowStock, outOfStock)}
                </div>
            `;
        }

        async function openInventoryDetails(id) {
            const res = await apiFetch(`/inventory/${id}`);
            if (!res || !res.success) return;
            const item = res.data;

            openModal(`Stock Item — ${item.name}`, `
                <div style="font-size:13px; line-height:1.6;">
                    <p><strong>Shop:</strong> ${item.shop ? item.shop.name : 'Shop #' + item.shop_id}</p>
                    <p><strong>Category:</strong> ${item.category || 'N/A'} | <strong>Brand/Model:</strong> ${item.brand || ''} ${item.model || ''}</p>
                    <p><strong>SKU:</strong> <code>${item.sku || 'N/A'}</code></p>
                    <p><strong>Stock Level:</strong> ${item.current_stock} (Min threshold: ${item.minimum_stock})</p>
                    <p><strong>Purchase Cost:</strong> ₹${parseFloat(item.purchase_price).toFixed(2)} | <strong>Selling Price:</strong> ₹${parseFloat(item.selling_price).toFixed(2)}</p>
                    <hr style="margin:12px 0; border:0; border-top:1px solid #e2e8f0;">

                    <h4 style="font-size:13px; font-weight:700; margin-bottom:6px;">Stock Movement Logs</h4>
                    <ul style="list-style:none; padding:0;">
                        ${(item.stock_movements || []).length === 0 ? '<li style="color:#94a3b8;">No stock movement history recorded.</li>' : ''}
                        ${(item.stock_movements || []).map(m => `
                            <li style="padding:6px; border-bottom:1px solid #e2e8f0; display:flex; justify-content:space-between;">
                                <span>${m.movement_type.toUpperCase()} (${m.quantity > 0 ? '+' + m.quantity : m.quantity}) — ${m.reference_type || ''}</span>
                                <span style="font-size:11px; color:#64748b;">${new Date(m.created_at).toLocaleString()}</span>
                            </li>
                        `).join('')}
                    </ul>
                </div>
            `);
        }

        // 16. SHOP EXPENSES VIEW
        async function loadExpensesView(page = 1, search = '', shopId = '', categoryId = '', dateFrom = '', dateTo = '') {
            const content = getContentContainer();
            content.innerHTML = '<div style="padding:20px; color:#64748b;">Loading shop expenses...</div>';

            const query = `/expenses?page=${page}&search=${encodeURIComponent(search)}&shop_id=${shopId}&category_id=${categoryId}&date_from=${dateFrom}&date_to=${dateTo}`;
            const res = await apiFetch(query);
            if (!res || !res.success) return;

            const pageData = res.data;
            const expenses = pageData.data || [];
            const sum = pageData.summary || { total_expense_amount: 0, expenses_count: 0 };
            const shopsOptions = await getShopsDropdownOptions(shopId);

            content.innerHTML = `
                <div class="grid-4" style="grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));">
                    <div class="metric-card">
                        <div class="metric-title">Total Expenses Logged</div>
                        <div class="metric-value">${sum.expenses_count}</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-title">Total Expenses Amount</div>
                        <div class="metric-value" style="color:#dc2626;">₹${sum.total_expense_amount.toLocaleString()}</div>
                    </div>
                </div>

                <div class="card-table">
                    <div class="table-toolbar">
                        <div style="display:flex; gap:10px; flex:1; min-width:280px;">
                            <div class="search-box" style="flex:1;">
                                <input type="text" id="expenses-search-input" placeholder="Search expense title, category, reference, shop..." value="${search}" oninput="debounceSearch(() => loadExpensesView(1, document.getElementById('expenses-search-input').value, '${shopId}', '${categoryId}', '${dateFrom}', '${dateTo}'))">
                            </div>
                        </div>
                        <div style="display:flex; gap:10px; flex-wrap:wrap; align-items:center;">
                            <select class="filter-select" onchange="loadExpensesView(1, '${search}', this.value, '${categoryId}', '${dateFrom}', '${dateTo}')">
                                ${shopsOptions}
                            </select>
                            <input type="date" class="filter-select" value="${dateFrom}" title="From Date" onchange="loadExpensesView(1, '${search}', '${shopId}', '${categoryId}', this.value, '${dateTo}')">
                            <input type="date" class="filter-select" value="${dateTo}" title="To Date" onchange="loadExpensesView(1, '${search}', '${shopId}', '${categoryId}', '${dateFrom}', this.value)">
                            ${(search || shopId || categoryId || dateFrom || dateTo) ? `<button class="btn-sm" style="background:#e2e8f0; color:#334155;" onclick="loadExpensesView(1, '', '', '', '', '')">Clear Filters</button>` : ''}
                        </div>
                    </div>
                    <div class="table-responsive">
                    <table>
                        <thead>
                            <tr>
                                <th>Expense Title</th>
                                <th>Shop Name</th>
                                <th>Category</th>
                                <th>Expense Date</th>
                                <th>Amount</th>
                                <th>Payment Method</th>
                                <th>Reference / Notes</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${expenses.length === 0 ? `<tr><td colspan="7" style="text-align:center; padding:30px; color:#94a3b8;">No shop expenses found matching criteria.</td></tr>` : ''}
                            ${expenses.map(e => `
                                <tr>
                                    <td><strong>${e.title}</strong></td>
                                    <td>${e.shop ? e.shop.name : 'Shop #' + e.shop_id}</td>
                                    <td><span class="badge badge-trial">${e.category ? e.category.name : 'General'}</span></td>
                                    <td>${new Date(e.expense_date || e.created_at).toLocaleDateString()}</td>
                                    <td><strong style="color:#dc2626;">₹${parseFloat(e.amount).toFixed(2)}</strong></td>
                                    <td>${e.payment_method || 'Cash'}</td>
                                    <td>${e.reference_number || e.notes || '—'}</td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                    </div>
                    ${renderPagination(pageData, 'loadExpensesView', search, shopId, categoryId, dateFrom, dateTo)}
                </div>
            `;
        }

        // 17. WARRANTIES VIEW
        async function loadWarrantiesView(page = 1, search = '', shopId = '', status = '') {
            const content = getContentContainer();
            content.innerHTML = '<div style="padding:20px; color:#64748b;">Loading warranties...</div>';

            const query = `/warranties?page=${page}&search=${encodeURIComponent(search)}&shop_id=${shopId}&status=${status}`;
            const res = await apiFetch(query);
            if (!res || !res.success) return;

            const pageData = res.data;
            const warranties = pageData.data || [];
            const sum = pageData.summary || { total_count: 0, active_count: 0 };
            const shopsOptions = await getShopsDropdownOptions(shopId);

            content.innerHTML = `
                <div class="grid-4" style="grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));">
                    <div class="metric-card">
                        <div class="metric-title">Total Warranties</div>
                        <div class="metric-value">${sum.total_count}</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-title">Active Warranties</div>
                        <div class="metric-value" style="color:#16a34a;">${sum.active_count}</div>
                    </div>
                </div>

                <div class="card-table">
                    <div class="table-toolbar">
                        <div style="display:flex; gap:10px; flex:1; min-width:280px;">
                            <div class="search-box" style="flex:1;">
                                <input type="text" id="warranties-search-input" placeholder="Search warranty #, customer, shop..." value="${search}" oninput="debounceSearch(() => loadWarrantiesView(1, document.getElementById('warranties-search-input').value, '${shopId}', '${status}'))">
                            </div>
                        </div>
                        <div style="display:flex; gap:10px; flex-wrap:wrap; align-items:center;">
                            <select class="filter-select" onchange="loadWarrantiesView(1, '${search}', this.value, '${status}')">
                                ${shopsOptions}
                            </select>
                            ${(search || shopId || status) ? `<button class="btn-sm" style="background:#e2e8f0; color:#334155;" onclick="loadWarrantiesView(1, '', '', '')">Clear Filters</button>` : ''}
                        </div>
                    </div>
                    <div class="table-responsive">
                    <table>
                        <thead>
                            <tr>
                                <th>Warranty #</th>
                                <th>Shop Name</th>
                                <th>Customer & Device</th>
                                <th>Start Date</th>
                                <th>End Date</th>
                                <th>Status</th>
                                <th>Claims Logged</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${warranties.length === 0 ? `<tr><td colspan="7" style="text-align:center; padding:30px; color:#94a3b8;">No warranty records found matching criteria.</td></tr>` : ''}
                            ${warranties.map(w => {
                                const wCust = w.customer ? w.customer.name : (w.customer_name || 'Walk-in Customer / N/A');
                                const wCustMob = w.customer ? (w.customer.mobile || '') : '';
                                const wDev = w.device ? `${w.device.brand || ''} ${w.device.model || ''}`.trim() : (w.device_model || 'N/A');
                                return `
                                <tr>
                                    <td><strong><code>${w.warranty_number || 'WAR-' + w.id}</code></strong></td>
                                    <td>${w.shop ? w.shop.name : 'Shop #' + w.shop_id}</td>
                                    <td><strong>${wCust}</strong>${wCustMob ? `<br><span style="font-size:11px; color:#64748b;">📞 ${wCustMob}</span>` : ''}<br><span style="font-size:11px; color:#2563eb;">📱 ${wDev}</span></td>
                                    <td>${new Date(w.warranty_start_date).toLocaleDateString()}</td>
                                    <td>${new Date(w.warranty_end_date).toLocaleDateString()}</td>
                                    <td><span class="badge ${w.status === 'active' ? 'badge-active' : 'badge-inactive'}">${w.status}</span></td>
                                    <td>${(w.claims || []).length} Claims</td>
                                </tr>
                                `;
                            }).join('')}
                        </tbody>
                    </table>
                    </div>
                    ${renderPagination(pageData, 'loadWarrantiesView', search, shopId, status)}
                </div>
            `;
        }

        // 18. TECHNICIANS VIEW
        async function loadTechniciansView(page = 1, search = '', shopId = '') {
            const content = getContentContainer();
            content.innerHTML = '<div style="padding:20px; color:#64748b;">Loading technicians directory...</div>';

            const query = `/technicians?page=${page}&search=${encodeURIComponent(search)}&shop_id=${shopId}`;
            const res = await apiFetch(query);
            if (!res || !res.success) return;

            const pageData = res.data;
            const techs = pageData.data || [];
            const shopsOptions = await getShopsDropdownOptions(shopId);

            content.innerHTML = `
                <div class="card-table">
                    <div class="table-toolbar">
                        <div style="display:flex; gap:10px; flex:1; min-width:280px;">
                            <div class="search-box" style="flex:1;">
                                <input type="text" id="techs-search-input" placeholder="Search technician name, mobile, specialization, shop..." value="${search}" oninput="debounceSearch(() => loadTechniciansView(1, document.getElementById('techs-search-input').value, '${shopId}'))">
                            </div>
                        </div>
                        <div style="display:flex; gap:10px; flex-wrap:wrap; align-items:center;">
                            <select class="filter-select" onchange="loadTechniciansView(1, '${search}', this.value)">
                                ${shopsOptions}
                            </select>
                            ${(search || shopId) ? `<button class="btn-sm" style="background:#e2e8f0; color:#334155;" onclick="loadTechniciansView(1, '', '')">Clear Filters</button>` : ''}
                        </div>
                    </div>
                    <div class="table-responsive">
                    <table>
                        <thead>
                            <tr>
                                <th>Technician Name</th>
                                <th>Mobile Number</th>
                                <th>Specialization</th>
                                <th>Associated Shop</th>
                                <th>Total Jobs</th>
                                <th>Completed Jobs</th>
                                <th>Total Earnings</th>
                                <th>Total Paid</th>
                                <th>Payable Balance</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${techs.length === 0 ? `<tr><td colspan="9" style="text-align:center; padding:30px; color:#94a3b8;">No technicians found matching criteria.</td></tr>` : ''}
                            ${techs.map(t => `
                                <tr>
                                    <td><strong>${t.name}</strong></td>
                                    <td>${t.mobile}</td>
                                    <td>${t.specialization || 'General Repair'}</td>
                                    <td>${t.shop ? t.shop.name : 'Shop #' + t.shop_id}</td>
                                    <td>${t.total_jobs_count || 0}</td>
                                    <td>${t.completed_jobs_count || 0}</td>
                                    <td>₹${parseFloat(t.total_earnings || 0).toFixed(2)}</td>
                                    <td style="color:#16a34a;">₹${parseFloat(t.total_paid || 0).toFixed(2)}</td>
                                    <td><strong style="color:${t.total_payable > 0 ? '#d97706' : '#64748b'};">₹${parseFloat(t.total_payable || 0).toFixed(2)}</strong></td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                    </div>
                    ${renderPagination(pageData, 'loadTechniciansView', search, shopId)}
                </div>
            `;
        }

        // ==========================================
        // 20. USED MOBILES & FEATURE ADOPTION VIEWS
        // ==========================================

        // TAB 1: SHOPS / USERS USING THE USED MOBILE FEATURE
        async function loadUsedMobileUsersView(page = 1, search = '') {
            const content = getContentContainer();
            content.innerHTML = '<div style="padding:28px; color:#64748b; text-align:center;"><div style="font-size:28px; margin-bottom:8px;">⏳</div>Loading shops using Used Mobile feature...</div>';

            const data = await apiFetch(`/used-mobiles/users?page=${page}&search=${encodeURIComponent(search)}`);
            if (!data || !data.success) {
                content.innerHTML = '<div style="padding:24px; color:#ef4444; text-align:center;">Failed to load Used Mobile user adoption data.</div>';
                return;
            }

            const pageData = data.data;
            const shops = pageData.data || [];
            const summary = pageData.summary || {
                total_shops_using: 0,
                total_devices: 0,
                total_in_stock: 0,
                total_sold: 0,
                total_invested: 0,
                total_profit: 0
            };

            content.innerHTML = `
                <!-- Overall Adoption Matrix KPI Cards -->
                <div class="grid-4" style="grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); margin-bottom:18px;">
                    <div class="metric-card" style="border-left:4px solid #8b5cf6;">
                        <div class="metric-title">Active Shops Using</div>
                        <div class="metric-value" style="color:#7c3aed;">${summary.total_shops_using}</div>
                        <div class="metric-sub" style="color:#64748b;">Shops bought/sold used phones</div>
                    </div>
                    <div class="metric-card" style="border-left:4px solid #3b82f6;">
                        <div class="metric-title">Total Devices Logged</div>
                        <div class="metric-value" style="color:#2563eb;">${summary.total_devices}</div>
                        <div class="metric-sub" style="color:#64748b;">Across all registered shops</div>
                    </div>
                    <div class="metric-card" style="border-left:4px solid #f59e0b;">
                        <div class="metric-title">Current In Stock</div>
                        <div class="metric-value" style="color:#d97706;">${summary.total_in_stock}</div>
                        <div class="metric-sub" style="color:#64748b;">Available for resale</div>
                    </div>
                    <div class="metric-card" style="border-left:4px solid #10b981;">
                        <div class="metric-title">Total Sold Devices</div>
                        <div class="metric-value" style="color:#059669;">${summary.total_sold}</div>
                        <div class="metric-sub" style="color:#64748b;">Completed sales to buyers</div>
                    </div>
                    <div class="metric-card" style="border-left:4px solid #059669;">
                        <div class="metric-title">Total Shop Profit</div>
                        <div class="metric-value" style="color:#059669;">₹${(summary.total_profit || 0).toLocaleString()}</div>
                        <div class="metric-sub" style="color:#64748b;">Total invested: ₹${(summary.total_invested || 0).toLocaleString()}</div>
                    </div>
                </div>

                <div class="card-table">
                    <div class="table-toolbar">
                        <div style="display:flex; gap:10px; flex:1; min-width:280px; align-items:center;">
                            <div class="search-box" style="flex:1;">
                                <input type="text" id="used-mobile-users-search" placeholder="Search shop name, owner name, mobile, email, city..." value="${search}" oninput="debounceSearch(() => loadUsedMobileUsersView(1, document.getElementById('used-mobile-users-search').value))">
                            </div>
                            ${search ? `<button class="btn-sm" style="background:#e2e8f0; color:#334155;" onclick="loadUsedMobileUsersView(1, '')">Clear</button>` : ''}
                        </div>
                        <div style="display:flex; gap:10px; align-items:center;">
                            <button class="btn-sm" style="background:#8b5cf6; color:white; border:none; padding:8px 14px; font-weight:600; cursor:pointer;" onclick="switchNav('used-mobiles', 'devices')">
                                📱 View All Devices Ledger →
                            </button>
                        </div>
                    </div>

                    <div class="table-responsive">
                    <table>
                        <thead>
                            <tr>
                                <th>Shop Name & Location</th>
                                <th>Owner / Account</th>
                                <th>Purchased</th>
                                <th>In Stock</th>
                                <th>Sold</th>
                                <th>Total Invested</th>
                                <th>Total Profit</th>
                                <th>Last Activity</th>
                                <th>Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${shops.length === 0 ? `
                                <tr>
                                    <td colspan="9" style="text-align:center; padding:36px; color:#94a3b8;">
                                        <div style="font-size:32px; margin-bottom:8px;">📱</div>
                                        <strong>No shops found using the Used Mobile feature yet.</strong>
                                        <div style="font-size:12px; margin-top:4px;">As soon as shop owners start purchasing or selling used phones from the mobile app, their stats will appear here.</div>
                                    </td>
                                </tr>
                            ` : ''}
                            ${shops.map(s => {
                                const m = s.metrics || {};
                                const lastAct = m.last_activity_at ? new Date(m.last_activity_at).toLocaleDateString([], { day:'numeric', month:'short', year:'numeric' }) : 'N/A';
                                return `
                                <tr>
                                    <td>
                                        <div style="font-weight:700; color:#0f172a; font-size:14px;">${s.shop_name}</div>
                                        <div style="font-size:12px; color:#64748b; margin-top:2px;">📍 ${s.city || 'N/A'}${s.state ? ', ' + s.state : ''}</div>
                                    </td>
                                    <td>
                                        <div style="font-weight:600; color:#1e293b;">${s.owner_name}</div>
                                        <div style="font-size:12px; color:#64748b; margin-top:2px;">
                                            ${s.mobile ? `📞 <a href="tel:${s.mobile}" style="color:#2563eb; text-decoration:none;">${s.mobile}</a>` : ''}
                                            ${s.email ? `<div style="font-size:11px; color:#94a3b8;">✉️ ${s.email}</div>` : ''}
                                        </div>
                                    </td>
                                    <td><span style="font-weight:700; font-size:14px; color:#1e293b;">${m.total_purchased || 0}</span></td>
                                    <td><span class="badge" style="background:#fef3c7; color:#92400e; font-weight:700;">${m.in_stock_count || 0} In Stock</span></td>
                                    <td><span class="badge badge-active" style="font-weight:700;">${m.sold_count || 0} Sold</span></td>
                                    <td><strong>₹${(m.total_invested || 0).toLocaleString()}</strong></td>
                                    <td><strong style="color:#059669; font-size:14px;">₹${(m.total_profit || 0).toLocaleString()}</strong></td>
                                    <td style="font-size:12px; color:#64748b;">${lastAct}</td>
                                    <td>
                                        <button class="btn-sm" style="background:#eff6ff; color:#2563eb; border:1px solid #bfdbfe; font-weight:600; padding:5px 10px; cursor:pointer;" onclick="switchNav('used-mobiles', 'devices'); setTimeout(() => loadUsedMobileDevicesView(1, '', '', '${s.shop_id}'), 60);" title="View all devices of ${s.shop_name}">
                                            📱 View Devices
                                        </button>
                                    </td>
                                </tr>
                                `;
                            }).join('')}
                        </tbody>
                    </table>
                    </div>
                    ${renderPagination(pageData, 'loadUsedMobileUsersView', search)}
                </div>
            `;
        }

        // TAB 2: ALL USED MOBILES LEDGER ACROSS PLATFORM
        async function loadUsedMobileDevicesView(page = 1, search = '', status = '', shopId = '', dateFrom = '', dateTo = '') {
            const content = getContentContainer();
            const shopOptions = await getShopsDropdownOptions(shopId);

            content.innerHTML = '<div style="padding:28px; color:#64748b; text-align:center;"><div style="font-size:28px; margin-bottom:8px;">⏳</div>Loading used mobile devices ledger...</div>';

            const query = `/used-mobiles?page=${page}&search=${encodeURIComponent(search)}&status=${status}&shop_id=${shopId}&date_from=${dateFrom}&date_to=${dateTo}`;
            const res = await apiFetch(query);
            if (!res || !res.success) {
                content.innerHTML = '<div style="padding:24px; color:#ef4444; text-align:center;">Failed to load used mobiles list.</div>';
                return;
            }

            const pageData = res.data;
            const mobiles = pageData.data || [];
            const summary = pageData.summary || {
                total_devices: 0,
                total_in_stock: 0,
                total_sold: 0,
                total_invested: 0,
                total_profit: 0
            };

            content.innerHTML = `
                <!-- Device Metrics -->
                <div class="grid-4" style="grid-template-columns: repeat(auto-fit, minmax(160px, 1fr)); margin-bottom:18px;">
                    <div class="metric-card" style="padding:14px 18px;">
                        <div class="metric-title">Filtered Devices</div>
                        <div class="metric-value" style="font-size:20px;">${summary.total_devices}</div>
                    </div>
                    <div class="metric-card" style="padding:14px 18px; border-left:3px solid #f59e0b;">
                        <div class="metric-title">In Stock</div>
                        <div class="metric-value" style="font-size:20px; color:#d97706;">${summary.total_in_stock}</div>
                    </div>
                    <div class="metric-card" style="padding:14px 18px; border-left:3px solid #10b981;">
                        <div class="metric-title">Sold</div>
                        <div class="metric-value" style="font-size:20px; color:#059669;">${summary.total_sold}</div>
                    </div>
                    <div class="metric-card" style="padding:14px 18px; border-left:3px solid #2563eb;">
                        <div class="metric-title">Total Invested</div>
                        <div class="metric-value" style="font-size:20px; color:#2563eb;">₹${(summary.total_invested || 0).toLocaleString()}</div>
                    </div>
                    <div class="metric-card" style="padding:14px 18px; border-left:3px solid #059669;">
                        <div class="metric-title">Total Profit</div>
                        <div class="metric-value" style="font-size:20px; color:#059669;">₹${(summary.total_profit || 0).toLocaleString()}</div>
                    </div>
                </div>

                <div class="card-table">
                    <div class="table-toolbar">
                        <div style="display:flex; gap:10px; flex:1; min-width:280px; align-items:center;">
                            <div class="search-box" style="flex:1;">
                                <input type="text" id="used-devices-search-input" placeholder="Search brand, model, IMEI, ref #, seller, buyer..." value="${search}" oninput="debounceSearch(() => loadUsedMobileDevicesView(1, document.getElementById('used-devices-search-input').value, '${status}', '${shopId}', '${dateFrom}', '${dateTo}'))">
                            </div>
                        </div>
                        <div style="display:flex; gap:10px; flex-wrap:wrap; align-items:center;">
                            <select class="filter-select" onchange="loadUsedMobileDevicesView(1, '${search}', this.value, '${shopId}', '${dateFrom}', '${dateTo}')">
                                <option value="" ${status === '' ? 'selected' : ''}>All Statuses</option>
                                <option value="in_stock" ${status === 'in_stock' ? 'selected' : ''}>In Stock</option>
                                <option value="sold" ${status === 'sold' ? 'selected' : ''}>Sold</option>
                            </select>
                            <select class="filter-select" onchange="loadUsedMobileDevicesView(1, '${search}', '${status}', this.value, '${dateFrom}', '${dateTo}')">
                                ${shopOptions}
                            </select>
                            ${(search || status || shopId || dateFrom || dateTo) ? `
                                <button class="btn-sm" style="background:#e2e8f0; color:#334155;" onclick="loadUsedMobileDevicesView(1, '', '', '', '', '')">Reset</button>
                            ` : ''}
                        </div>
                    </div>

                    <div class="table-responsive">
                    <table>
                        <thead>
                            <tr>
                                <th>Ref # / Invoice</th>
                                <th>Shop</th>
                                <th>Device</th>
                                <th>IMEI 1</th>
                                <th>Seller (Bought From)</th>
                                <th>Purchase Cost</th>
                                <th>Status</th>
                                <th>Sale & Profit</th>
                                <th>Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${mobiles.length === 0 ? `
                                <tr>
                                    <td colspan="9" style="text-align:center; padding:32px; color:#94a3b8;">No used mobile records match the current filters.</td>
                                </tr>
                            ` : ''}
                            ${mobiles.map(m => {
                                const isSold = m.status === 'sold';
                                const badgeClass = isSold ? 'badge-active' : 'badge-trial';
                                const statusLabel = isSold ? 'Sold' : 'In Stock';
                                const pDate = m.purchase_date ? new Date(m.purchase_date).toLocaleDateString([], { day:'numeric', month:'short', year:'numeric' }) : 'N/A';
                                const shopName = m.shop ? m.shop.name : ('Shop #' + m.shop_id);
                                return `
                                <tr>
                                    <td>
                                        <div style="font-weight:700; color:#2563eb; font-size:13px;">${m.purchase_ref_number || ('UMB-' + m.id)}</div>
                                        ${m.sale_invoice_number ? `<div style="font-size:11px; color:#059669; font-weight:600;">🧾 ${m.sale_invoice_number}</div>` : ''}
                                    </td>
                                    <td>
                                        <div style="font-weight:600; color:#0f172a;">${shopName}</div>
                                        ${m.shop && m.shop.city ? `<div style="font-size:11px; color:#64748b;">📍 ${m.shop.city}</div>` : ''}
                                    </td>
                                    <td>
                                        <div style="font-weight:700; color:#0f172a;">${m.brand} ${m.model}</div>
                                        <div style="font-size:12px; color:#64748b;">${m.storage ? m.storage : ''}${m.ram ? ' / ' + m.ram : ''}${m.color ? ' • ' + m.color : ''}</div>
                                    </td>
                                    <td>
                                        <span style="font-family:monospace; background:#f1f5f9; padding:2px 6px; border-radius:4px; font-size:12px; font-weight:600; letter-spacing:0.5px;">${m.imei1 || 'N/A'}</span>
                                    </td>
                                    <td>
                                        <div style="font-weight:600; color:#1e293b;">${m.seller_name || 'N/A'}</div>
                                        <div style="font-size:12px; color:#64748b;">${m.seller_phone || ''}</div>
                                    </td>
                                    <td>
                                        <div style="font-weight:600;">₹${Number(m.total_cost || m.purchase_price || 0).toLocaleString()}</div>
                                        <div style="font-size:11px; color:#64748b;">${pDate}</div>
                                    </td>
                                    <td>
                                        <span class="badge ${badgeClass}">${statusLabel}</span>
                                    </td>
                                    <td>
                                        ${isSold ? `
                                            <div style="font-weight:600; color:#0f172a;">₹${Number(m.selling_price || 0).toLocaleString()}</div>
                                            <div style="font-size:12px; color:#059669; font-weight:700;">+₹${Number(m.profit || 0).toLocaleString()} profit</div>
                                        ` : `
                                            <span style="color:#94a3b8; font-size:12px;">In Inventory</span>
                                        `}
                                    </td>
                                    <td>
                                        <button class="btn-sm" style="background:#f1f5f9; color:#0f172a; border:1px solid #cbd5e1; font-weight:600; padding:5px 10px; cursor:pointer;" onclick="openUsedMobileDetails(${m.id})">
                                            👁️ View
                                        </button>
                                    </td>
                                </tr>
                                `;
                            }).join('')}
                        </tbody>
                    </table>
                    </div>
                    ${renderPagination(pageData, 'loadUsedMobileDevicesView', search, status, shopId, dateFrom, dateTo)}
                </div>
            `;
        }

        // MODAL: COMPLETE USED MOBILE DETAILS & ID VERIFICATION
        async function openUsedMobileDetails(id) {
            openModal('📱 Used Mobile Record Details', `
                <div style="padding:28px; text-align:center; color:#64748b;">
                    <div style="font-size:28px; margin-bottom:8px;">⏳</div>
                    <div>Loading device details...</div>
                </div>
            `, '760px');

            const res = await apiFetch(`/used-mobiles/${id}`);
            if (!res || !res.success || !res.data) {
                document.getElementById('modal-body').innerHTML = '<div style="color:#ef4444; padding:20px; text-align:center;">Failed to load device details.</div>';
                return;
            }

            const m = res.data;
            const isSold = m.status === 'sold';
            const shopName = m.shop ? m.shop.name : ('Shop #' + m.shop_id);
            const shopOwner = m.shop ? (m.shop.owner_name || (m.shop.user ? m.shop.user.name : '')) : '';
            const shopContact = m.shop ? (m.shop.mobile || m.shop.phone || '') : '';

            // ID proof images
            const idProofFront = m.id_proof_photo || '';
            const idProofBack = m.id_proof_back_photo || '';
            const sellerPhoto = m.seller_photo || '';

            const html = `
                <div style="font-size:13px; line-height:1.5; color:#1e293b;">
                    <!-- Shop & Header Bar -->
                    <div style="background:#f8fafc; border:1px solid #e2e8f0; border-radius:10px; padding:14px; margin-bottom:16px; display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:10px;">
                        <div>
                            <div style="font-weight:700; font-size:16px; color:#0f172a;">${m.brand} ${m.model}</div>
                            <div style="font-size:12px; color:#64748b; margin-top:2px;">
                                🏪 <strong>${shopName}</strong> ${shopOwner ? `(${shopOwner})` : ''} ${shopContact ? `• 📞 ${shopContact}` : ''}
                            </div>
                        </div>
                        <div style="text-align:right;">
                            <span class="badge ${isSold ? 'badge-active' : 'badge-trial'}" style="font-size:12px; padding:4px 10px;">
                                ${isSold ? '✓ SOLD' : '📦 IN STOCK'}
                            </span>
                            <div style="font-size:11px; color:#64748b; margin-top:4px;">Ref: <strong>${m.purchase_ref_number || ('UMB-' + m.id)}</strong></div>
                        </div>
                    </div>

                    <!-- 2 Columns Grid for Device & Seller -->
                    <div style="display:grid; grid-template-columns:repeat(auto-fit, minmax(320px, 1fr)); gap:14px; margin-bottom:16px;">
                        <!-- Column 1: Device Details -->
                        <div style="background:white; border:1px solid #e2e8f0; border-radius:10px; padding:14px;">
                            <div style="font-weight:700; font-size:13px; color:#2563eb; text-transform:uppercase; margin-bottom:10px; border-bottom:1px solid #f1f5f9; padding-bottom:6px;">
                                📱 Device Specifications
                            </div>
                            <table style="width:100%; font-size:12px; border-collapse:collapse;">
                                <tr><td style="color:#64748b; padding:4px 0;">Brand & Model:</td><td style="font-weight:600; padding:4px 0;">${m.brand} ${m.model}</td></tr>
                                <tr><td style="color:#64748b; padding:4px 0;">IMEI 1:</td><td style="font-family:monospace; font-weight:700; padding:4px 0; color:#0f172a;">${m.imei1 || 'N/A'}</td></tr>
                                ${m.imei2 ? `<tr><td style="color:#64748b; padding:4px 0;">IMEI 2:</td><td style="font-family:monospace; padding:4px 0;">${m.imei2}</td></tr>` : ''}
                                ${m.serial_number ? `<tr><td style="color:#64748b; padding:4px 0;">Serial No:</td><td style="font-family:monospace; padding:4px 0;">${m.serial_number}</td></tr>` : ''}
                                <tr><td style="color:#64748b; padding:4px 0;">RAM / Storage:</td><td style="font-weight:600; padding:4px 0;">${m.ram || '-'} / ${m.storage || '-'}</td></tr>
                                <tr><td style="color:#64748b; padding:4px 0;">Color:</td><td style="font-weight:600; padding:4px 0;">${m.color || 'N/A'}</td></tr>
                                <tr><td style="color:#64748b; padding:4px 0;">Condition:</td><td style="padding:4px 0;"><span class="badge" style="background:#e0f2fe; color:#0369a1;">${m.device_condition || 'Normal'}</span></td></tr>
                                ${m.battery_health ? `<tr><td style="color:#64748b; padding:4px 0;">Battery Health:</td><td style="font-weight:600; padding:4px 0;">${m.battery_health}</td></tr>` : ''}
                                ${m.condition_notes ? `<tr><td style="color:#64748b; padding:4px 0;">Condition Notes:</td><td style="padding:4px 0;">${m.condition_notes}</td></tr>` : ''}
                            </table>
                        </div>

                        <!-- Column 2: Seller & Purchase Verification -->
                        <div style="background:white; border:1px solid #e2e8f0; border-radius:10px; padding:14px;">
                            <div style="font-weight:700; font-size:13px; color:#059669; text-transform:uppercase; margin-bottom:10px; border-bottom:1px solid #f1f5f9; padding-bottom:6px;">
                                👤 Seller Verification & Purchase
                            </div>
                            <table style="width:100%; font-size:12px; border-collapse:collapse;">
                                <tr><td style="color:#64748b; padding:4px 0;">Seller Name:</td><td style="font-weight:700; padding:4px 0;">${m.seller_name || 'N/A'}</td></tr>
                                <tr><td style="color:#64748b; padding:4px 0;">Seller Mobile:</td><td style="padding:4px 0;">${m.seller_phone ? `📞 <a href="tel:${m.seller_phone}" style="color:#2563eb; text-decoration:none;">${m.seller_phone}</a>` : 'N/A'}</td></tr>
                                ${m.seller_address ? `<tr><td style="color:#64748b; padding:4px 0;">Seller Address:</td><td style="padding:4px 0;">${m.seller_address}</td></tr>` : ''}
                                <tr><td style="color:#64748b; padding:4px 0;">ID Proof Type:</td><td style="font-weight:600; padding:4px 0;">${m.id_proof_type || 'Aadhaar Card'}</td></tr>
                                <tr><td style="color:#64748b; padding:4px 0;">ID Number:</td><td style="font-family:monospace; font-weight:700; padding:4px 0;">${m.id_proof_number || 'N/A'}</td></tr>
                                <tr><td style="color:#64748b; padding:4px 0;">Purchase Date:</td><td style="padding:4px 0;">${m.purchase_date ? new Date(m.purchase_date).toLocaleDateString() : 'N/A'}</td></tr>
                                <tr><td style="color:#64748b; padding:4px 0;">Purchase Price:</td><td style="font-weight:700; padding:4px 0;">₹${Number(m.purchase_price || 0).toLocaleString()}</td></tr>
                                ${Number(m.repair_cost) > 0 ? `<tr><td style="color:#64748b; padding:4px 0;">Repair Cost:</td><td style="font-weight:600; color:#dc2626; padding:4px 0;">+₹${Number(m.repair_cost).toLocaleString()}</td></tr>` : ''}
                                <tr><td style="color:#64748b; padding:4px 0; border-top:1px dashed #e2e8f0;">Total Cost:</td><td style="font-weight:700; color:#0f172a; padding:4px 0; border-top:1px dashed #e2e8f0;">₹${Number(m.total_cost || m.purchase_price || 0).toLocaleString()}</td></tr>
                            </table>
                        </div>
                    </div>

                    <!-- ID Proof Photos Section (if uploaded) -->
                    ${(idProofFront || idProofBack || sellerPhoto) ? `
                        <div style="background:#f8fafc; border:1px solid #e2e8f0; border-radius:10px; padding:14px; margin-bottom:16px;">
                            <div style="font-weight:700; font-size:13px; color:#475569; margin-bottom:10px;">
                                📷 Verification Document Photos
                            </div>
                            <div style="display:flex; gap:14px; flex-wrap:wrap;">
                                ${idProofFront ? `
                                    <div style="text-align:center;">
                                        <div style="font-size:11px; color:#64748b; margin-bottom:4px; font-weight:600;">ID Proof (Front)</div>
                                        <a href="${idProofFront}" target="_blank" title="Click to view full image">
                                            <img src="${idProofFront}" alt="ID Proof Front" style="width:130px; height:85px; object-fit:cover; border-radius:6px; border:1px solid #cbd5e1; box-shadow:0 1px 3px rgba(0,0,0,0.1);">
                                        </a>
                                    </div>
                                ` : ''}
                                ${idProofBack ? `
                                    <div style="text-align:center;">
                                        <div style="font-size:11px; color:#64748b; margin-bottom:4px; font-weight:600;">ID Proof (Back)</div>
                                        <a href="${idProofBack}" target="_blank" title="Click to view full image">
                                            <img src="${idProofBack}" alt="ID Proof Back" style="width:130px; height:85px; object-fit:cover; border-radius:6px; border:1px solid #cbd5e1; box-shadow:0 1px 3px rgba(0,0,0,0.1);">
                                        </a>
                                    </div>
                                ` : ''}
                                ${sellerPhoto ? `
                                    <div style="text-align:center;">
                                        <div style="font-size:11px; color:#64748b; margin-bottom:4px; font-weight:600;">Seller Photo</div>
                                        <a href="${sellerPhoto}" target="_blank" title="Click to view full image">
                                            <img src="${sellerPhoto}" alt="Seller Photo" style="width:85px; height:85px; object-fit:cover; border-radius:6px; border:1px solid #cbd5e1; box-shadow:0 1px 3px rgba(0,0,0,0.1);">
                                        </a>
                                    </div>
                                ` : ''}
                            </div>
                        </div>
                    ` : ''}

                    <!-- Sale Details (If Sold) -->
                    ${isSold ? `
                        <div style="background:#ecfdf5; border:1px solid #a7f3d0; border-radius:10px; padding:14px; margin-bottom:14px;">
                            <div style="font-weight:700; font-size:13px; color:#065f46; text-transform:uppercase; margin-bottom:10px; border-bottom:1px solid #d1fae5; padding-bottom:6px;">
                                🧾 Sale & Customer Delivery Details
                            </div>
                            <div style="display:grid; grid-template-columns:repeat(auto-fit, minmax(280px, 1fr)); gap:12px;">
                                <table style="width:100%; font-size:12px; border-collapse:collapse;">
                                    <tr><td style="color:#047857; padding:4px 0;">Invoice #:</td><td style="font-weight:700; padding:4px 0;">${m.sale_invoice_number || 'N/A'}</td></tr>
                                    <tr><td style="color:#047857; padding:4px 0;">Sale Date:</td><td style="padding:4px 0;">${m.sale_date ? new Date(m.sale_date).toLocaleDateString() : 'N/A'}</td></tr>
                                    <tr><td style="color:#047857; padding:4px 0;">Buyer Name:</td><td style="font-weight:700; padding:4px 0;">${m.buyer_name || 'N/A'}</td></tr>
                                    <tr><td style="color:#047857; padding:4px 0;">Buyer Mobile:</td><td style="padding:4px 0;">${m.buyer_phone ? `📞 <a href="tel:${m.buyer_phone}" style="color:#2563eb; text-decoration:none;">${m.buyer_phone}</a>` : 'N/A'}</td></tr>
                                    ${m.buyer_address ? `<tr><td style="color:#047857; padding:4px 0;">Buyer Address:</td><td style="padding:4px 0;">${m.buyer_address}</td></tr>` : ''}
                                </table>
                                <table style="width:100%; font-size:12px; border-collapse:collapse;">
                                    <tr><td style="color:#047857; padding:4px 0;">Selling Price:</td><td style="font-weight:700; font-size:14px; padding:4px 0; color:#0f172a;">₹${Number(m.selling_price || 0).toLocaleString()}</td></tr>
                                    <tr><td style="color:#047857; padding:4px 0;">Total Cost:</td><td style="padding:4px 0;">₹${Number(m.total_cost || 0).toLocaleString()}</td></tr>
                                    <tr><td style="color:#047857; padding:4px 0;">Net Profit:</td><td style="font-weight:800; font-size:15px; color:#059669; padding:4px 0;">+₹${Number(m.profit || 0).toLocaleString()} (${m.profit_percentage || 0}%)</td></tr>
                                    <tr><td style="color:#047857; padding:4px 0;">Warranty:</td><td style="font-weight:600; padding:4px 0;">${m.warranty_days ? m.warranty_days + ' Days' : 'No Warranty'}</td></tr>
                                    ${m.sale_payment_mode ? `<tr><td style="color:#047857; padding:4px 0;">Payment Mode:</td><td style="padding:4px 0;">${m.sale_payment_mode.toUpperCase()}</td></tr>` : ''}
                                </table>
                            </div>
                        </div>
                    ` : ''}

                    <div style="text-align:right; margin-top:14px;">
                        <button class="btn-sm" style="background:#64748b; color:white; border:none; padding:8px 18px; cursor:pointer;" onclick="closeModal()">Close</button>
                    </div>
                </div>
            `;

            document.getElementById('modal-body').innerHTML = html;
        }

        // 19. PLATFORM BUSINESS INTELLIGENCE & FINANCIAL REPORTS VIEW
        async function loadReportsView(range = '30days', shopId = '', startDate = '', endDate = '') {
            const content = getContentContainer();
            content.innerHTML = '<div style="padding:20px; color:#64748b;">Generating multi-dimensional platform business report...</div>';

            const query = `/reports/summary?date_range=${range}&shop_id=${shopId}&start_date=${startDate}&end_date=${endDate}`;
            const res = await apiFetch(query);
            if (!res || !res.success) return;

            const rep = res.data;
            const fin = rep.financials;
            const shopsOptions = await getShopsDropdownOptions(shopId);

            content.innerHTML = `
                <div style="margin-bottom:20px; background:white; padding:18px 24px; border-radius:12px; border:1px solid #e2e8f0; display:flex; gap:14px; flex-wrap:wrap; align-items:center; justify-content:space-between;">
                    <div>
                        <h3 style="font-size:16px; font-weight:700;">📊 Platform Business Analytics & Financial Matrix</h3>
                        <p style="font-size:13px; color:#64748b; margin-top:2px;">Aggregated financial reporting across all registered mobile shop businesses.</p>
                    </div>
                    <div style="display:flex; gap:10px; flex-wrap:wrap; align-items:center;">
                        <select class="filter-select" onchange="loadReportsView(this.value, '${shopId}', '${startDate}', '${endDate}')">
                            <option value="today" ${range === 'today' ? 'selected' : ''}>Today</option>
                            <option value="yesterday" ${range === 'yesterday' ? 'selected' : ''}>Yesterday</option>
                            <option value="7days" ${range === '7days' ? 'selected' : ''}>Last 7 Days</option>
                            <option value="30days" ${range === '30days' ? 'selected' : ''}>Last 30 Days</option>
                            <option value="this_month" ${range === 'this_month' ? 'selected' : ''}>This Month</option>
                            <option value="last_month" ${range === 'last_month' ? 'selected' : ''}>Last Month</option>
                            <option value="this_year" ${range === 'this_year' ? 'selected' : ''}>This Year</option>
                            <option value="all" ${range === 'all' ? 'selected' : ''}>All Time</option>
                        </select>
                        <select class="filter-select" onchange="loadReportsView('${range}', this.value, '${startDate}', '${endDate}')">
                            ${shopsOptions}
                        </select>
                    </div>
                </div>

                <div class="grid-4" style="grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));">
                    <div class="metric-card" style="border-left:4px solid #2563eb;">
                        <div class="metric-title">Gross Sales Revenue</div>
                        <div class="metric-value">₹${fin.total_sales_revenue.toLocaleString()}</div>
                        <div class="metric-sub">Paid: ₹${fin.total_sales_paid.toLocaleString()} | Due: ₹${fin.total_sales_due.toLocaleString()}</div>
                    </div>
                    <div class="metric-card" style="border-left:4px solid #d97706;">
                        <div class="metric-title">Repairs Revenue</div>
                        <div class="metric-value">₹${fin.total_repair_cost.toLocaleString()}</div>
                        <div class="metric-sub">Paid: ₹${fin.total_repair_paid.toLocaleString()} | Due: ₹${fin.total_repair_due.toLocaleString()}</div>
                    </div>
                    <div class="metric-card" style="border-left:4px solid #dc2626;">
                        <div class="metric-title">Total Shop Expenses</div>
                        <div class="metric-value" style="color:#dc2626;">₹${fin.total_shop_expenses.toLocaleString()}</div>
                        <div class="metric-sub">${rep.expenses.count} Expense Entries Logged</div>
                    </div>
                    <div class="metric-card" style="border-left:4px solid #16a34a; background:#f0fdf4;">
                        <div class="metric-title" style="color:#166534;">Net Platform Business Profit</div>
                        <div class="metric-value" style="color:${fin.net_platform_profit >= 0 ? '#15803d' : '#b91c1c'};">₹${fin.net_platform_profit.toLocaleString()}</div>
                        <div class="metric-sub" style="color:#15803d;">Gross Income: ₹${fin.total_gross_income.toLocaleString()}</div>
                    </div>
                </div>

                <div style="display:grid; grid-template-columns:1fr 1fr; gap:20px; margin-bottom:24px;">
                    <div class="card-table" style="padding:20px;">
                        <h4 style="font-size:14px; font-weight:700; margin-bottom:12px;">🛒 Sales & Repairs Volume Breakdown</h4>
                        <div style="display:flex; justify-style:space-around; text-align:center; padding:14px; background:#f8fafc; border-radius:8px; margin-bottom:14px;">
                            <div>
                                <div style="font-size:22px; font-weight:700; color:#2563eb;">${rep.sales.count}</div>
                                <div style="font-size:12px; color:#64748b;">Sales Invoices</div>
                            </div>
                            <div>
                                <div style="font-size:22px; font-weight:700; color:#d97706;">${rep.repairs.count}</div>
                                <div style="font-size:12px; color:#64748b;">Repair Jobs</div>
                            </div>
                        </div>
                        <h5 style="font-size:12px; font-weight:700; text-transform:uppercase; color:#64748b; margin-bottom:8px;">Repair Status Summary</h5>
                        <div style="display:flex; gap:8px; flex-wrap:wrap;">
                            ${(rep.repairs.status_breakdown || []).map(sb => `
                                <span class="badge badge-trial" style="padding:6px 12px; font-size:12px;">
                                    ${sb.repair_status.toUpperCase()}: <strong>${sb.count}</strong>
                                </span>
                            `).join('')}
                        </div>
                    </div>

                    <div class="card-table" style="padding:20px;">
                        <h4 style="font-size:14px; font-weight:700; margin-bottom:12px;">📦 Inventory Stock Health & Valuation</h4>
                        <div style="display:grid; grid-template-columns:1fr 1fr; gap:10px; margin-bottom:14px;">
                            <div style="background:#f8fafc; padding:10px; border-radius:8px;">
                                <div style="font-size:11px; color:#64748b; font-weight:600;">STOCK COST VALUATION</div>
                                <div style="font-size:18px; font-weight:700; color:#0f172a;">₹${rep.inventory.cost_valuation.toLocaleString()}</div>
                            </div>
                            <div style="background:#f8fafc; padding:10px; border-radius:8px;">
                                <div style="font-size:11px; color:#64748b; font-weight:600;">EXPECTED SELLING VALUATION</div>
                                <div style="font-size:18px; font-weight:700; color:#10b981;">₹${rep.inventory.selling_valuation.toLocaleString()}</div>
                            </div>
                        </div>
                        <div style="display:flex; gap:10px;">
                            <div style="flex:1; background:#fef3c7; padding:10px; border-radius:8px; color:#b45309; text-align:center;">
                                <strong>${rep.inventory.low_stock_count}</strong> Items Low in Stock
                            </div>
                            <div style="flex:1; background:#fee2e2; padding:10px; border-radius:8px; color:#b91c1c; text-align:center;">
                                <strong>${rep.inventory.out_of_stock_count}</strong> Items Out of Stock
                            </div>
                        </div>
                    </div>
                </div>

                <div class="card-table">
                    <div class="table-toolbar">
                        <div style="font-weight:700; font-size:15px;">Shop-wise Financial Performance Comparison</div>
                    </div>
                    <table>
                        <thead>
                            <tr>
                                <th>Shop Name</th>
                                <th>Owner</th>
                                <th>Sales Revenue</th>
                                <th>Repairs Revenue</th>
                                <th>Gross Revenue</th>
                                <th>Shop Expenses</th>
                                <th>Net Profit</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${(rep.shop_performance || []).length === 0 ? '<tr><td colspan="7" style="text-align:center; padding:30px; color:#94a3b8;">No shop activity recorded for selected range.</td></tr>' : ''}
                            ${(rep.shop_performance || []).map(sp => `
                                <tr>
                                    <td><strong>${sp.shop_name}</strong></td>
                                    <td>${sp.owner_name}</td>
                                    <td>₹${sp.sales_rev.toLocaleString()}</td>
                                    <td>₹${sp.repairs_rev.toLocaleString()}</td>
                                    <td><strong>₹${sp.gross_rev.toLocaleString()}</strong></td>
                                    <td style="color:#dc2626;">₹${sp.expenses.toLocaleString()}</td>
                                    <td><strong style="color:${sp.net_profit >= 0 ? '#16a34a' : '#dc2626'};">₹${sp.net_profit.toLocaleString()}</strong></td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                </div>
            `;
        }

        // MODAL HELPERS
        function openModal(title, htmlContent, maxWidth = '540px') {
            document.getElementById('modal-title').innerText = title;
            document.getElementById('modal-body').innerHTML = htmlContent;
            const modalContent = document.querySelector('.modal-content');
            if (modalContent) {
                modalContent.style.maxWidth = maxWidth;
            }
            document.getElementById('modal-container').style.display = 'flex';
        }

        function closeModal() {
            document.getElementById('modal-container').style.display = 'none';
            const modalContent = document.querySelector('.modal-content');
            if (modalContent) {
                modalContent.style.maxWidth = '540px';
            }
        }
    
        // ==========================================
        // PUSH NOTIFICATIONS BROADCAST VIEW
        // ==========================================
        let allNotificationUsers = [];

        async function loadNotificationsView() {
            const content = getContentContainer();
            content.innerHTML = `
                <div style="display:flex; flex-direction:column; gap:20px;">
                    <!-- BROADCAST FORM CARD -->
                    <div style="background:#ffffff; border:1px solid #e2e8f0; border-radius:12px; padding:24px; box-shadow:0 1px 3px rgba(0,0,0,0.05);">
                        <div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:18px; border-bottom:1px solid #f1f5f9; padding-bottom:12px;">
                            <div>
                                <h3 style="font-size:18px; font-weight:700; color:#0f172a; margin:0;"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="display:inline-block; vertical-align:-2px; margin-right:6px;"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg> Send Push Notification</h3>
                                <p style="font-size:13px; color:#64748b; margin:4px 0 0 0;">Create and broadcast custom notifications with title, description, image, and targeted user filters.</p>
                            </div>
                        </div>

                        <form id="notif-broadcast-form" onsubmit="event.preventDefault(); sendNotificationBroadcast();">
                            <div style="display:grid; grid-template-columns:1fr; gap:16px;">
                                <!-- Quick Engagement Templates Bar -->
                                <div>
                                    <label style="display:block; font-size:13px; font-weight:700; color:#334155; margin-bottom:8px;"><svg width="15" height="15" viewBox="0 0 24 24" fill="#f59e0b" style="display:inline-block; vertical-align:-2px; margin-right:4px;"><path d="M13 2L3 14h7v8l10-12h-7z"/></svg> Quick Engagement Templates (Click to Auto-Fill):</label>
                                    <div style="display:flex; gap:8px; flex-wrap:wrap;">
                                        <button type="button" onclick="applyNotifTemplate('repair')" style="padding:6px 12px; font-size:12px; background:#eff6ff; color:#1d4ed8; border:1px solid #bfdbfe; border-radius:6px; font-weight:600; cursor:pointer; display:inline-flex; align-items:center; gap:6px;"><svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z"/></svg> Add First Repair</button>
                                        <button type="button" onclick="applyNotifTemplate('sale')" style="padding:6px 12px; font-size:12px; background:#dcfce7; color:#15803d; border:1px solid #bbf7d0; border-radius:6px; font-weight:600; cursor:pointer; display:inline-flex; align-items:center; gap:6px;"><svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="6" width="20" height="12" rx="2"/><circle cx="12" cy="12" r="2"/><path d="M6 12h.01M18 12h.01"/></svg> Record First Sale</button>
                                        <button type="button" onclick="applyNotifTemplate('profit')" style="padding:6px 12px; font-size:12px; background:#fef3c7; color:#b45309; border:1px solid #fde68a; border-radius:6px; font-weight:600; cursor:pointer; display:inline-flex; align-items:center; gap:6px;"><svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/></svg> Check Daily Profit</button>
                                        <button type="button" onclick="applyNotifTemplate('pending')" style="padding:6px 12px; font-size:12px; background:#f3e8ff; color:#6b21a8; border:1px solid #e9d5ff; border-radius:6px; font-weight:600; cursor:pointer; display:inline-flex; align-items:center; gap:6px;"><svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg> Pending Job Reminder</button>
                                        <button type="button" onclick="applyNotifTemplate('intelligence')" style="padding:6px 12px; font-size:12px; background:#fee2e2; color:#b91c1c; border:1px solid #fecaca; border-radius:6px; font-weight:600; cursor:pointer; display:inline-flex; align-items:center; gap:6px;"><svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4.5 16.5c-1.5 1.26-2 5-2 5s3.74-.5 5-2c.71-.71 1.26-1.5 1.63-2.37l-2.26-2.26C6 15.24 5.21 15.79 4.5 16.5z"/><path d="M12 15l-3-3 7.5-7.5c.83-.83 2.17-.83 3 0s.83 2.17 0 3L12 15z"/></svg> Profit Intelligence</button>
                                    </div>
                                </div>
                                <!-- Title -->
                                <div>
                                    <label style="display:block; font-size:13px; font-weight:600; color:#334155; margin-bottom:6px;">Notification Title <span style="color:#ef4444;">*</span></label>
                                    <input type="text" id="notif-title" placeholder="e.g. Special Offer / System Update" required style="width:100%; padding:10px 14px; border:1px solid #cbd5e1; border-radius:8px; font-size:14px; outline:none; box-sizing:border-box;">
                                </div>

                                <!-- Description -->
                                <div>
                                    <label style="display:block; font-size:13px; font-weight:600; color:#334155; margin-bottom:6px;">Notification Description / Message <span style="color:#ef4444;">*</span></label>
                                    <textarea id="notif-description" rows="3" placeholder="Enter message body details to display in user notification..." required style="width:100%; padding:10px 14px; border:1px solid #cbd5e1; border-radius:8px; font-size:14px; outline:none; resize:vertical; box-sizing:border-box;"></textarea>
                                </div>

                                <!-- Image Upload & URL -->
                                <div style="display:grid; grid-template-columns:1fr 1fr; gap:16px;">
                                    <div>
                                        <label style="display:block; font-size:13px; font-weight:600; color:#334155; margin-bottom:6px;">Upload Image File (Optional)</label>
                                        <input type="file" id="notif-image-file" accept="image/*" onchange="previewNotifImage(this)" style="width:100%; padding:8px; border:1px solid #cbd5e1; border-radius:8px; font-size:13px; background:#f8fafc;">
                                    </div>
                                    <div>
                                        <label style="display:block; font-size:13px; font-weight:600; color:#334155; margin-bottom:6px;">OR Image Direct URL (Optional)</label>
                                        <input type="url" id="notif-image-url" placeholder="https://example.com/banner.jpg" oninput="previewNotifImageUrl(this.value)" style="width:100%; padding:10px 14px; border:1px solid #cbd5e1; border-radius:8px; font-size:14px; box-sizing:border-box;">
                                    </div>
                                </div>

                                <!-- Image Preview Container -->
                                <div id="notif-preview-box" style="display:none; align-items:center; gap:12px; padding:10px; background:#f8fafc; border:1px dashed #cbd5e1; border-radius:8px;">
                                    <img id="notif-preview-img" src="" alt="Notification Image Preview" style="max-height:80px; max-width:140px; border-radius:6px; object-fit:cover;">
                                    <div>
                                        <span style="font-weight:600; font-size:12px; color:#334155;">Image Preview Selected</span>
                                        <br><button type="button" onclick="clearNotifImage()" style="background:none; border:none; color:#ef4444; font-size:12px; cursor:pointer; padding:0; margin-top:4px; font-weight:600;">Remove Image</button>
                                    </div>
                                </div>

                                <!-- Filter Target Audience -->
                                <div>
                                    <label style="display:block; font-size:13px; font-weight:600; color:#334155; margin-bottom:8px;">Target Audience Filter <span style="color:#ef4444;">*</span></label>
                                    <div style="display:flex; gap:16px; flex-wrap:wrap;">
                                        <label style="display:flex; align-items:center; gap:8px; background:#f1f5f9; padding:10px 16px; border-radius:8px; cursor:pointer; font-weight:600; font-size:13px; color:#1e293b;">
                                            <input type="radio" name="notif_target" value="all" checked onchange="toggleNotifTargetUI('all')">
                                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="display:inline-block; vertical-align:-2px; margin-right:4px;"><circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/></svg> All Users
                                        </label>
                                        <label style="display:flex; align-items:center; gap:8px; background:#f1f5f9; padding:10px 16px; border-radius:8px; cursor:pointer; font-weight:600; font-size:13px; color:#1e293b;">
                                            <input type="radio" name="notif_target" value="active" onchange="toggleNotifTargetUI('active')">
                                            <span style="display:inline-block; width:8px; height:8px; background-color:#22c55e; border-radius:50%; margin-right:4px; vertical-align:1px;"></span> Active Users Only
                                        </label>
                                        <label style="display:flex; align-items:center; gap:8px; background:#f1f5f9; padding:10px 16px; border-radius:8px; cursor:pointer; font-weight:600; font-size:13px; color:#1e293b;">
                                            <input type="radio" name="notif_target" value="selected" onchange="toggleNotifTargetUI('selected')">
                                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="display:inline-block; vertical-align:-2px; margin-right:4px;"><circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="6"/><circle cx="12" cy="12" r="2"/></svg> Select Particular Users
                                        </label>
                                    </div>
                                </div>

                                <!-- Particular User Selection Container -->
                                <div id="notif-user-selection-box" style="display:none; border:1px solid #cbd5e1; border-radius:10px; padding:16px; background:#f8fafc;">
                                    <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:12px; flex-wrap:wrap; gap:10px;">
                                        <span style="font-weight:700; font-size:14px; color:#0f172a;">Select Specific Recipient Users</span>
                                        <div style="display:flex; gap:8px;">
                                            <button type="button" onclick="selectAllNotifUsers(true)" style="padding:6px 12px; font-size:12px; background:#e2e8f0; color:#334155; border:none; border-radius:6px; font-weight:600; cursor:pointer;">Select All</button>
                                            <button type="button" onclick="selectAllNotifUsers(false)" style="padding:6px 12px; font-size:12px; background:#e2e8f0; color:#334155; border:none; border-radius:6px; font-weight:600; cursor:pointer;">Deselect All</button>
                                        </div>
                                    </div>

                                    <input type="text" id="notif-user-search" placeholder="Search user by name, phone, shop..." oninput="filterNotifUserChecklist()" style="width:100%; padding:8px 12px; border:1px solid #cbd5e1; border-radius:6px; font-size:13px; margin-bottom:10px; box-sizing:border-box;">

                                    <div id="notif-users-checklist" style="max-height:220px; overflow-y:auto; display:flex; flex-direction:column; gap:6px; padding:4px;">
                                        <div style="text-align:center; color:#64748b; padding:12px; font-size:13px;">Loading user list...</div>
                                    </div>
                                </div>

                                <!-- Submit Button -->
                                <div style="display:flex; justify-content:flex-end; margin-top:8px;">
                                    <button type="submit" id="notif-submit-btn" style="background:#2563eb; color:#ffffff; font-weight:700; padding:12px 24px; border:none; border-radius:8px; font-size:14px; cursor:pointer; display:inline-flex; align-items:center; gap:8px;">
                                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4.5 16.5c-1.5 1.26-2 5-2 5s3.74-.5 5-2c.71-.71 1.26-1.5 1.63-2.37l-2.26-2.26C6 15.24 5.21 15.79 4.5 16.5z"/><path d="M12 15l-3-3 7.5-7.5c.83-.83 2.17-.83 3 0s.83 2.17 0 3L12 15z"/></svg> Send Notification Now
                                    </button>
                                </div>
                            </div>
                        </form>
                    </div>

                    <!-- SENT NOTIFICATIONS HISTORY TABLE -->
                    <div style="background:#ffffff; border:1px solid #e2e8f0; border-radius:12px; padding:24px; box-shadow:0 1px 3px rgba(0,0,0,0.05);">
                        <h4 style="font-size:16px; font-weight:700; color:#0f172a; margin:0 0 16px 0;"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="display:inline-block; vertical-align:-2px; margin-right:6px;"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/></svg> Sent Broadcast History</h4>
                        <div style="overflow-x:auto;">
                            <table class="data-table" style="width:100%; border-collapse:collapse;">
                                <thead>
                                    <tr style="background:#f8fafc; border-bottom:1px solid #e2e8f0; text-align:left; font-size:12px; text-transform:uppercase; color:#64748b;">
                                        <th style="padding:12px;">Image</th>
                                        <th style="padding:12px;">Title & Message</th>
                                        <th style="padding:12px;">Target Filter</th>
                                        <th style="padding:12px;">Recipients</th>
                                        <th style="padding:12px;">Sent Date</th>
                                        <th style="padding:12px; text-align:right;">Action</th>
                                    </tr>
                                </thead>
                                <tbody id="notif-history-tbody">
                                    <tr><td colspan="6" style="text-align:center; padding:20px; color:#64748b;">Loading history...</td></tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            `;

            fetchNotificationUsers();
            loadNotificationHistory();
        }

        async function fetchNotificationUsers() {
            const data = await apiFetch('/notifications/users');
            if (data && data.success) {
                allNotificationUsers = data.data || [];
                renderNotifUsersChecklist(allNotificationUsers);
            }
        }

        function renderNotifUsersChecklist(users) {
            const container = document.getElementById('notif-users-checklist');
            if (!container) return;
            if (users.length === 0) {
                container.innerHTML = '<div style="color:#64748b; font-size:13px; text-align:center; padding:12px;">No matching users found.</div>';
                return;
            }

            container.innerHTML = users.map(u => `
                <label style="display:flex; align-items:center; justify-content:space-between; padding:8px 12px; background:#ffffff; border:1px solid #e2e8f0; border-radius:6px; cursor:pointer; font-size:13px;">
                    <div style="display:flex; align-items:center; gap:10px;">
                        <input type="checkbox" class="notif-user-chk" value="${u.id}">
                        <div>
                            <span style="font-weight:700; color:#0f172a;">${u.name}</span>
                            <span style="color:#64748b; font-size:12px; margin-left:6px;">(${u.mobile})</span>
                        </div>
                    </div>
                    <div style="display:flex; align-items:center; gap:8px;">
                        <span style="font-size:11px; background:#eff6ff; color:#2563eb; font-weight:600; padding:2px 8px; border-radius:4px;">${u.shop_name}</span>
                        <span style="font-size:11px; font-weight:700; padding:2px 8px; border-radius:4px; ${u.is_opened_today ? 'background:#dcfce7; color:#15803d;' : 'background:#f1f5f9; color:#64748b;'}">
                            ${u.is_opened_today ? '<span style="display:inline-block; width:6px; height:6px; background-color:#22c55e; border-radius:50%; margin-right:3px; vertical-align:1px;"></span> Opened Today' : 'Last: ' + (u.last_opened || 'Never')}
                        </span>
                    </div>
                </label>
            `).join('');
        }

        function filterNotifUserChecklist() {
            const q = (document.getElementById('notif-user-search')?.value || '').toLowerCase().trim();
            const filtered = allNotificationUsers.filter(u =>
                u.name.toLowerCase().includes(q) ||
                u.mobile.toLowerCase().includes(q) ||
                u.shop_name.toLowerCase().includes(q) ||
                (u.email && u.email.toLowerCase().includes(q))
            );
            renderNotifUsersChecklist(filtered);
        }

        function selectAllNotifUsers(select) {
            document.querySelectorAll('.notif-user-chk').forEach(chk => chk.checked = select);
        }

        function toggleNotifTargetUI(targetType) {
            const box = document.getElementById('notif-user-selection-box');
            if (box) {
                box.style.display = targetType === 'selected' ? 'block' : 'none';
            }
        }

        function previewNotifImage(input) {
            if (input.files && input.files[0]) {
                const reader = new FileReader();
                reader.onload = function(e) {
                    const previewBox = document.getElementById('notif-preview-box');
                    const previewImg = document.getElementById('notif-preview-img');
                    if (previewBox && previewImg) {
                        previewImg.src = e.target.result;
                        previewBox.style.display = 'flex';
                    }
                };
                reader.readAsDataURL(input.files[0]);
                const urlInput = document.getElementById('notif-image-url');
                if (urlInput) urlInput.value = '';
            }
        }

        function previewNotifImageUrl(url) {
            if (url && url.trim().startsWith('http')) {
                const previewBox = document.getElementById('notif-preview-box');
                const previewImg = document.getElementById('notif-preview-img');
                if (previewBox && previewImg) {
                    previewImg.src = url.trim();
                    previewBox.style.display = 'flex';
                }
            }
        }

        function clearNotifImage() {
            const fileInput = document.getElementById('notif-image-file');
            const urlInput = document.getElementById('notif-image-url');
            const previewBox = document.getElementById('notif-preview-box');
            if (fileInput) fileInput.value = '';
            if (urlInput) urlInput.value = '';
            if (previewBox) previewBox.style.display = 'none';
        }

        
        function applyNotifTemplate(type) {
            const titleInput = document.getElementById('notif-title');
            const descInput = document.getElementById('notif-description');

            const templates = {
                'repair': {
                    title: '\u{1F6E0}\u{FE0F} Add Your First Repair Job!',
                    desc: 'Track repair status, technician fees, and spare parts easily! Tap to add your repair job now.'
                },
                'sale': {
                    title: '\u{1F4B0} Boost Your Shop Sales Today!',
                    desc: 'Keep track of device & accessory sales, print customer invoices, and view daily shop profit.'
                },
                'profit': {
                    title: '\u{1F4C8} How much profit did you make today?',
                    desc: 'Open MyRepairHub to check your daily profit breakdown and net earnings report.'
                },
                'pending': {
                    title: '\u{23F0} Update Pending Repair Jobs',
                    desc: 'Keep your customers happy! Update pending repair statuses and deliver completed devices.'
                },
                'intelligence': {
                    title: '\u{1F680} Discover Profit Leaks & Extra Earnings!',
                    desc: 'Check Profit Intelligence to find unused stock, technician margins, and grow your shop profits.'
                }
            };

            if (templates[type] && titleInput && descInput) {
                titleInput.value = templates[type].title;
                descInput.value = templates[type].desc;
            }
        }

        async function sendNotificationBroadcast() {
            const title = document.getElementById('notif-title').value.trim();
            const description = document.getElementById('notif-description').value.trim();
            const targetType = document.querySelector('input[name="notif_target"]:checked')?.value || 'all';

            if (!title || !description) {
                alert('Please enter title and description.');
                return;
            }

            let selectedUserIds = [];
            if (targetType === 'selected') {
                document.querySelectorAll('.notif-user-chk:checked').forEach(chk => {
                    selectedUserIds.push(parseInt(chk.value));
                });
                if (selectedUserIds.length === 0) {
                    alert('Please select at least one user from the list.');
                    return;
                }
            }

            if (!confirm(`Are you sure you want to send this notification to ${targetType === 'selected' ? selectedUserIds.length + ' selected user(s)' : targetType + ' users'}?`)) return;

            const submitBtn = document.getElementById('notif-submit-btn');
            if (submitBtn) {
                submitBtn.disabled = true;
                submitBtn.innerHTML = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="display:inline-block; vertical-align:-2px; margin-right:6px;"><path d="M4.5 16.5c-1.5 1.26-2 5-2 5s3.74-.5 5-2c.71-.71 1.26-1.5 1.63-2.37l-2.26-2.26C6 15.24 5.21 15.79 4.5 16.5z"/><path d="M12 15l-3-3 7.5-7.5c.83-.83 2.17-.83 3 0s.83 2.17 0 3L12 15z"/></svg> Sending Notification...';
            }

            const formData = new FormData();
            formData.append('title', title);
            formData.append('description', description);
            formData.append('target_type', targetType);

            if (targetType === 'selected') {
                selectedUserIds.forEach(id => formData.append('selected_user_ids[]', id));
            }

            const fileInput = document.getElementById('notif-image-file');
            const urlInput = document.getElementById('notif-image-url');
            if (fileInput && fileInput.files[0]) {
                formData.append('image', fileInput.files[0]);
            } else if (urlInput && urlInput.value.trim()) {
                formData.append('image_url', urlInput.value.trim());
            }

            try {
                const response = await fetch(`${API_BASE}/notifications/send`, {
                    method: 'POST',
                    headers: {
                        'Authorization': `Bearer ${authToken}`,
                        'Accept': 'application/json'
                    },
                    body: formData
                });
                const data = await response.json();

                if (data.success) {
                    alert(data.message || 'Notification broadcast sent successfully!');
                    loadNotificationsView();
                } else {
                    alert(data.message || 'Failed to send notification.');
                }
            } catch (err) {
                alert('Error sending notification: ' + err.message);
            } finally {
                if (submitBtn) {
                    submitBtn.disabled = false;
                    submitBtn.innerHTML = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4.5 16.5c-1.5 1.26-2 5-2 5s3.74-.5 5-2c.71-.71 1.26-1.5 1.63-2.37l-2.26-2.26C6 15.24 5.21 15.79 4.5 16.5z"/><path d="M12 15l-3-3 7.5-7.5c.83-.83 2.17-.83 3 0s.83 2.17 0 3L12 15z"/></svg> Send Notification Now';
                }
            }
        }

        async function loadNotificationHistory() {
            const tbody = document.getElementById('notif-history-tbody');
            if (!tbody) return;

            const data = await apiFetch('/notifications');
            if (!data || !data.success) {
                tbody.innerHTML = '<tr><td colspan="6" style="text-align:center; padding:20px; color:#ef4444;">Failed to load history.</td></tr>';
                return;
            }

            const list = data.data?.data || [];
            if (list.length === 0) {
                tbody.innerHTML = '<tr><td colspan="6" style="text-align:center; padding:20px; color:#64748b;">No broadcast notifications sent yet.</td></tr>';
                return;
            }

            tbody.innerHTML = list.map(item => `
                <tr style="border-bottom:1px solid #f1f5f9;">
                    <td style="padding:10px;">
                        ${item.image_url ? `<img src="${item.image_url}" style="width:40px; height:40px; border-radius:6px; object-fit:cover;">` : '<span style="color:#94a3b8; font-size:12px;">No Image</span>'}
                    </td>
                    <td style="padding:10px;">
                        <div style="font-weight:700; color:#0f172a; font-size:14px;">${item.title}</div>
                        <div style="color:#64748b; font-size:12px; max-width:320px; text-overflow:ellipsis; overflow:hidden; white-space:nowrap;">${item.description}</div>
                    </td>
                    <td style="padding:10px;">
                        <span style="font-size:11px; font-weight:700; padding:4px 10px; border-radius:12px; text-transform:uppercase; ${item.target_type === 'all' ? 'background:#dbeafe; color:#1e40af;' : (item.target_type === 'active' ? 'background:#dcfce7; color:#15803d;' : 'background:#fef3c7; color:#92400e;')}">
                            ${item.target_type}
                        </span>
                    </td>
                    <td style="padding:10px; font-weight:700; color:#0f172a;">${item.recipients_count || 0} Users</td>
                    <td style="padding:10px; font-size:12px; color:#64748b;">${new Date(item.sent_at || item.created_at).toLocaleString()}</td>
                    <td style="padding:10px; text-align:right;">
                        <button onclick="deleteNotificationBroadcast(${item.id})" style="background:#fee2e2; color:#ef4444; border:none; padding:6px 12px; border-radius:6px; font-size:12px; font-weight:600; cursor:pointer;">Delete</button>
                    </td>
                </tr>
            `).join('');
        }

        async function deleteNotificationBroadcast(id) {
            if (!confirm('Are you sure you want to delete this notification record?')) return;
            const data = await apiFetch(`/notifications/${id}`, 'DELETE');
            if (data && data.success) {
                alert('Notification deleted.');
                loadNotificationHistory();
            }
        }

        // ==================== REFERRAL & POINTS MANAGEMENT ====================
        async function loadReferralsView(search = '', type = '', source = '') {
            const content = getContentContainer();
            if (!search && !type && !source) {
                content.innerHTML = '<div style="padding:20px; color:#64748b;">Loading referral & points settings...</div>';
            }

            const params = new URLSearchParams();
            if (search) params.set('search', search);
            if (type) params.set('type', type);
            if (source) params.set('source', source);
            const qs = params.toString() ? `?${params.toString()}` : '';

            const res = await apiFetch(`/referrals/overview${qs}`);
            if (!res || !res.success) {
                content.innerHTML = `<div class="alert-error" style="margin:20px;">Failed to load referral overview: ${res?.message || 'Unknown error'}</div>`;
                return;
            }

            const d = res.data || {};
            const cfg = d.global_config || {};
            const top = d.top_referrers || [];
            const txns = d.recent_transactions || [];
            const safeSearch = String(search).replace(/"/g, '&quot;');

            content.innerHTML = `
                <div class="grid-4">
                    <div class="metric-card">
                        <div class="metric-title">👥 Total Referred Shops</div>
                        <div class="metric-value" style="color:#4f46e5;">${d.total_referred_shops || 0}</div>
                        <div class="metric-sub" style="color:#64748b;">Shops joined via referral</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-title">🎁 Total Points Credited</div>
                        <div class="metric-value" style="color:#059669;">${parseFloat(d.total_credited || 0).toFixed(2)} <span style="font-size:14px; font-weight:600;">pts</span></div>
                        <div class="metric-sub">1 Point = ₹1 Plan Discount</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-title">💳 Total Points Redeemed</div>
                        <div class="metric-value" style="color:#d97706;">${parseFloat(d.total_redeemed || 0).toFixed(2)} <span style="font-size:14px; font-weight:600;">pts</span></div>
                        <div class="metric-sub" style="color:#64748b;">Used on plan recharges</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-title">⚙️ System Status</div>
                        <div class="metric-value" style="font-size:20px; color:${cfg.enabled ? '#059669' : '#dc2626'};">
                            ${cfg.enabled ? '✅ Enabled' : '⛔ Disabled'}
                        </div>
                        <div class="metric-sub" style="color:#64748b;">Mode: ${cfg.reward_mode === 'recharge_only' ? 'Recharge % Only' : 'Signup + Recharge %'}</div>
                    </div>
                </div>

                <div style="display:grid; grid-template-columns:repeat(auto-fit, minmax(290px, 1fr)); gap:20px; align-items:start;">
                    <div class="card-table" style="padding:24px;">
                        <div style="margin-bottom:16px; padding-bottom:12px; border-bottom:1px solid #f1f5f9;">
                            <h3 style="font-size:17px; font-weight:700; color:#0f172a; margin:0 0 4px 0;">🎁 Common Referral & Points Settings</h3>
                            <p style="font-size:12px; color:#64748b; margin:0;">Default rules applied to all shops unless overridden per shop in Shops Directory.</p>
                        </div>

                        <div id="ref-alert" class="alert-error" style="display:none;"></div>
                        <div id="ref-success" style="display:none; background:#f0fdf4; border:1px solid #bbf7d0; color:#166534; padding:12px; border-radius:8px; margin-bottom:14px; font-size:13px; font-weight:500;"></div>

                        <form onsubmit="saveReferralGlobalSettings(event)">
                            <div style="display:grid; grid-template-columns:repeat(auto-fit, minmax(180px, 1fr)); gap:14px;">
                                <div class="form-group">
                                    <label style="font-weight:600;">Referral System</label>
                                    <select id="ref-enabled" class="form-control">
                                        <option value="1" ${cfg.enabled ? 'selected' : ''}>✅ Enabled (Show in App)</option>
                                        <option value="0" ${!cfg.enabled ? 'selected' : ''}>⛔ Disabled (Hide from App)</option>
                                    </select>
                                </div>
                                <div class="form-group">
                                    <label style="font-weight:600;">Reward Mode</label>
                                    <select id="ref-mode" class="form-control">
                                        <option value="signup_and_recharge" ${(cfg.reward_mode || 'signup_and_recharge') === 'signup_and_recharge' ? 'selected' : ''}>Signup Points + Recharge %</option>
                                        <option value="recharge_only" ${cfg.reward_mode === 'recharge_only' ? 'selected' : ''}>Paid Recharge % Only</option>
                                    </select>
                                </div>
                            </div>

                            <div style="display:grid; grid-template-columns:repeat(auto-fit, minmax(180px, 1fr)); gap:14px; margin-top:10px;">
                                <div class="form-group">
                                    <label style="font-weight:600;">Referrer Signup Points</label>
                                    <input type="number" step="1" min="0" id="ref-signup-pts" class="form-control" value="${cfg.signup_points ?? 50}" required>
                                    <small style="color:#64748b; font-size:11px;">Earned by Shop A when Shop B signs up.</small>
                                </div>
                                <div class="form-group">
                                    <label style="font-weight:600;">New Shop Welcome Points</label>
                                    <input type="number" step="1" min="0" id="ref-welcome-pts" class="form-control" value="${cfg.welcome_points ?? 0}" required>
                                    <small style="color:#64748b; font-size:11px;">Bonus for Shop B on signup with code.</small>
                                </div>
                            </div>

                            <div style="display:grid; grid-template-columns:repeat(auto-fit, minmax(180px, 1fr)); gap:14px; margin-top:10px;">
                                <div class="form-group">
                                    <label style="font-weight:600;">Recharge Commission (%)</label>
                                    <input type="number" step="0.5" min="0" max="100" id="ref-recharge-pct" class="form-control" value="${cfg.recharge_percent ?? 10}" required>
                                    <small style="color:#64748b; font-size:11px;">% of cash paid by Shop B on every recharge.</small>
                                </div>
                                <div class="form-group">
                                    <label style="font-weight:600;">Max Points Redeemable (%)</label>
                                    <input type="number" step="1" min="0" max="100" id="ref-max-redeem" class="form-control" value="${cfg.max_redeem_percent ?? 50}" required>
                                    <small style="color:#64748b; font-size:11px;">Max % of a plan payable using points.</small>
                                </div>
                            </div>

                            <div class="form-group" style="margin-top:10px;">
                                <label style="font-weight:600;">App Download / Share Link</label>
                                <input type="text" id="ref-app-link" class="form-control" placeholder="https://play.google.com/store/apps/details?id=com.repairehub" value="${cfg.app_link || ''}">
                                <small style="color:#64748b; font-size:11px;">Included when shop owners share their referral code.</small>
                            </div>

                            <div style="margin-top:18px;">
                                <button type="submit" class="btn-primary" style="width:100%; padding:11px; font-weight:600;">Save Common Referral Settings</button>
                            </div>
                        </form>
                    </div>

                    <div class="card-table">
                        <div class="table-toolbar">
                            <div>
                                <h3 style="font-size:17px; font-weight:700; color:#0f172a; margin:0;">🏆 Top Referrer Shops</h3>
                                <p style="font-size:12px; color:#64748b; margin:2px 0 0 0;">Shops with the most referred signups & points.</p>
                            </div>
                        </div>
                        ${top.length === 0 ? '<div style="padding:36px 24px; text-align:center; color:#64748b; font-size:13px;">No referral activity yet. Once shops refer others, top performers appear here.</div>' : `
                            <div class="table-responsive">
                                <table style="width:100%; border-collapse:collapse;">
                                    <thead>
                                        <tr>
                                            <th>Shop</th>
                                            <th>Code</th>
                                            <th>Referred</th>
                                            <th>Balance</th>
                                            <th>Action</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        ${top.map(r => `
                                            <tr>
                                                <td>
                                                    <div style="font-weight:600;">${r.name || 'Shop #' + r.id}</div>
                                                    <div style="font-size:11px; color:#64748b;">${r.owner_name || ''}</div>
                                                </td>
                                                <td><code>${r.referral_code || '-'}</code></td>
                                                <td><strong>${r.referred_shops_count ?? 0}</strong></td>
                                                <td><span class="badge badge-active">${parseFloat(r.referral_points_balance || 0).toFixed(2)} pts</span></td>
                                                <td>
                                                    <button class="btn-sm" onclick="openShopReferralModal(${r.id}, '${(r.name || '').replace(/'/g, "\\'")}')">Manage</button>
                                                </td>
                                            </tr>
                                        `).join('')}
                                    </tbody>
                                </table>
                            </div>
                        `}
                    </div>
                </div>

                <div class="card-table" style="margin-top:20px;">
                    <div class="table-toolbar">
                        <div style="flex:1; min-width:240px;">
                            <h3 style="font-size:17px; font-weight:700; color:#0f172a; margin:0 0 6px 0;">📜 Recent Points Transactions</h3>
                            <div class="search-box">
                                <input type="text" id="referrals-search-input" placeholder="Search shop name, code, description..." value="${safeSearch}" oninput="debounceSearch(() => loadReferralsView(document.getElementById('referrals-search-input').value, '${type}', '${source}'))">
                            </div>
                        </div>
                        <div style="display:flex; gap:10px; flex-wrap:wrap; align-items:center;">
                            <select class="filter-select" onchange="loadReferralsView('${safeSearch}', this.value, '${source}')">
                                <option value="">Type: All</option>
                                <option value="credit" ${type === 'credit' ? 'selected' : ''}>+ Credit Only</option>
                                <option value="debit" ${type === 'debit' ? 'selected' : ''}>- Debit Only</option>
                            </select>
                            <select class="filter-select" onchange="loadReferralsView('${safeSearch}', '${type}', this.value)">
                                <option value="">Source: All</option>
                                <option value="signup_bonus" ${source === 'signup_bonus' ? 'selected' : ''}>Signup Bonus</option>
                                <option value="welcome_bonus" ${source === 'welcome_bonus' ? 'selected' : ''}>Welcome Bonus</option>
                                <option value="recharge_commission" ${source === 'recharge_commission' ? 'selected' : ''}>Recharge Commission</option>
                                <option value="plan_redeem" ${source === 'plan_redeem' ? 'selected' : ''}>Plan Redeem</option>
                                <option value="admin_credit" ${source === 'admin_credit' ? 'selected' : ''}>Admin Credit</option>
                                <option value="admin_debit" ${source === 'admin_debit' ? 'selected' : ''}>Admin Debit</option>
                            </select>
                            ${(search || type || source) ? `<button class="btn-sm" style="background:#e2e8f0; color:#334155;" onclick="loadReferralsView('', '', '')">Clear Filters</button>` : ''}
                        </div>
                    </div>
                    ${txns.length === 0 ? '<div style="padding:36px 24px; text-align:center; color:#64748b; font-size:13px;">No points transactions found matching filter criteria.</div>' : `
                        <div class="table-responsive">
                            <table style="width:100%; border-collapse:collapse;">
                                <thead>
                                    <tr>
                                        <th>Shop</th>
                                        <th>Type</th>
                                        <th>Source</th>
                                        <th>Points</th>
                                        <th>Balance After</th>
                                        <th>Payment Breakdown</th>
                                        <th>Description</th>
                                        <th>Date</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    ${txns.map(tx => {
                                        const pt = tx.payment_transaction;
                                        const gw = (pt && pt.gateway_response && typeof pt.gateway_response === 'object') ? pt.gateway_response : {};
                                        const cashPaid = pt ? parseFloat(pt.amount || 0) : (tx.meta && tx.meta.cash_paid !== undefined ? parseFloat(tx.meta.cash_paid) : null);
                                        const ptsUsed = gw.points_used !== undefined ? parseFloat(gw.points_used || 0) : null;
                                        const origAmt = gw.original_amount !== undefined ? parseFloat(gw.original_amount) : (cashPaid !== null && ptsUsed !== null ? cashPaid + ptsUsed : null);
                                        let breakdown = '<span style="color:#94a3b8;">—</span>';
                                        if (origAmt !== null && cashPaid !== null) {
                                            breakdown = `<div style="font-size:11px; line-height:1.45;">
                                                <div>Plan: <strong>₹${origAmt.toFixed(2)}</strong>${ptsUsed > 0 ? ` | Used: <strong style="color:#4f46e5;">${ptsUsed.toFixed(2)} pts</strong>` : ''}</div>
                                                <div>Cash Paid: <strong style="color:#059669;">₹${cashPaid.toFixed(2)}</strong>${tx.meta && tx.meta.commission_percent ? ` (${tx.meta.commission_percent}%)` : ''}</div>
                                            </div>`;
                                        } else if (cashPaid !== null) {
                                            breakdown = `<span style="font-size:11px;">Cash Paid: <strong>₹${cashPaid.toFixed(2)}</strong></span>`;
                                        }
                                        return `
                                        <tr>
                                            <td style="font-weight:600;">${tx.shop ? tx.shop.name : ('Shop #' + tx.shop_id)}</td>
                                            <td>
                                                <span class="badge ${tx.type === 'credit' ? 'badge-active' : 'badge-inactive'}">
                                                    ${tx.type === 'credit' ? '+ CREDIT' : '- DEBIT'}
                                                </span>
                                            </td>
                                            <td style="font-size:12px; text-transform:uppercase; color:#475569;">${tx.source || '-'}</td>
                                            <td style="font-weight:700; color:${tx.type === 'credit' ? '#059669' : '#dc2626'};">
                                                ${tx.type === 'credit' ? '+' : '-'}${parseFloat(tx.points || 0).toFixed(2)} pts
                                            </td>
                                            <td style="font-weight:600; color:#334155;">${parseFloat(tx.balance_after || 0).toFixed(2)} pts</td>
                                            <td>${breakdown}</td>
                                            <td style="font-size:12px; color:#475569;">${tx.description || '-'}</td>
                                            <td style="font-size:12px; color:#64748b;">${new Date(tx.created_at).toLocaleString()}</td>
                                        </tr>
                                    `;}).join('')}
                                </tbody>
                            </table>
                        </div>
                    `}
                </div>
            `;
        }

        async function saveReferralGlobalSettings(e) {
            e.preventDefault();
            const alertErr = document.getElementById('ref-alert');
            const alertSucc = document.getElementById('ref-success');
            alertErr.style.display = 'none';
            alertSucc.style.display = 'none';

            const body = {
                enabled: document.getElementById('ref-enabled').value === '1',
                reward_mode: document.getElementById('ref-mode').value,
                signup_points: parseFloat(document.getElementById('ref-signup-pts').value || 0),
                welcome_points: parseFloat(document.getElementById('ref-welcome-pts').value || 0),
                recharge_percent: parseFloat(document.getElementById('ref-recharge-pct').value || 0),
                max_redeem_percent: parseFloat(document.getElementById('ref-max-redeem').value || 0),
                app_link: document.getElementById('ref-app-link').value.trim(),
            };

            const res = await apiFetch('/referrals/settings', 'PUT', body);
            if (res && res.success) {
                alertSucc.textContent = 'Common referral & points settings saved successfully!';
                alertSucc.style.display = 'block';
                setTimeout(() => loadReferralsView(), 900);
            } else {
                alertErr.textContent = res?.message || 'Failed to save referral settings.';
                alertErr.style.display = 'block';
            }
        }

        async function openShopReferralModal(shopId, shopName) {
            openModal(`🎁 Shop-Wise Referral & Points — ${shopName}`, `<div style="padding:20px; color:#64748b;">Loading shop referral settings...</div>`, '620px');

            const res = await apiFetch(`/shops/${shopId}/referral-settings`);
            if (!res || !res.success) {
                openModal(`🎁 Shop-Wise Referral & Points — ${shopName}`, `<div class="alert-error">${res?.message || 'Failed to load shop referral settings.'}</div>`, '620px');
                return;
            }

            const d = res.data || {};
            const ov = d.overrides || {};
            const eff = d.effective_config || {};
            const glob = d.global_defaults || {};

            const enabledVal = ov.referral_enabled_override === null || ov.referral_enabled_override === undefined
                ? ''
                : (ov.referral_enabled_override ? '1' : '0');

            openModal(`🎁 Shop-Wise Referral & Points — ${d.shop_name || shopName}`, `
                <div style="font-size:13px;">
                    <div style="background:#f8fafc; border:1px solid #e2e8f0; border-radius:8px; padding:12px; margin-bottom:14px; display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:8px;">
                        <div><strong>Code:</strong> <code style="background:#e2e8f0; color:#0f172a; padding:2px 6px; border-radius:4px; font-weight:700;">${d.referral_code || 'N/A'}</code></div>
                        <div><strong>Current Wallet:</strong> <span class="badge" style="background:#4f46e5; color:#ffffff; font-weight:700;">${parseFloat(d.points_balance || 0).toFixed(2)} pts (₹${parseFloat(d.points_balance || 0).toFixed(2)})</span></div>
                        <div><strong>Referred By:</strong> ${d.referred_by_shop ? d.referred_by_shop.name : '<span style="color:#64748b;">Direct (No Referrer)</span>'}</div>
                    </div>

                    <div id="sref-alert" class="alert-error" style="display:none;"></div>
                    <div id="sref-success" style="display:none; background:#f0fdf4; border:1px solid #bbf7d0; color:#166534; padding:10px; border-radius:8px; margin-bottom:12px; font-size:13px;"></div>

                    <form onsubmit="saveShopReferralOverrides(event, ${shopId})">
                        <h4 style="font-size:13px; font-weight:700; color:#0f172a; margin-bottom:8px;">Shop-Wise Rule Overrides (Leave blank to use Common Default)</h4>
                        <div style="display:grid; grid-template-columns:1fr 1fr; gap:12px;">
                            <div class="form-group">
                                <label style="font-weight:600;">Referral Access</label>
                                <select id="sref-enabled" class="form-control">
                                    <option value="" ${enabledVal === '' ? 'selected' : ''}>Inherit Common (${glob.enabled ? 'Enabled' : 'Disabled'})</option>
                                    <option value="1" ${enabledVal === '1' ? 'selected' : ''}>✅ Force Enabled</option>
                                    <option value="0" ${enabledVal === '0' ? 'selected' : ''}>⛔ Force Disabled (Hide)</option>
                                </select>
                            </div>
                            <div class="form-group">
                                <label style="font-weight:600;">Reward Mode</label>
                                <select id="sref-mode" class="form-control">
                                    <option value="" ${!ov.referral_reward_mode_override ? 'selected' : ''}>Inherit Common (${glob.reward_mode || 'signup_and_recharge'})</option>
                                    <option value="signup_and_recharge" ${ov.referral_reward_mode_override === 'signup_and_recharge' ? 'selected' : ''}>Signup Points + Recharge %</option>
                                    <option value="recharge_only" ${ov.referral_reward_mode_override === 'recharge_only' ? 'selected' : ''}>Paid Recharge % Only</option>
                                </select>
                            </div>
                        </div>

                        <div style="display:grid; grid-template-columns:1fr 1fr 1fr; gap:10px; margin-top:8px;">
                            <div class="form-group">
                                <label style="font-weight:600;">Signup Pts</label>
                                <input type="number" step="1" min="0" id="sref-signup" class="form-control" placeholder="Default: ${glob.signup_points ?? 50}" value="${ov.custom_referral_signup_points ?? ''}">
                            </div>
                            <div class="form-group">
                                <label style="font-weight:600;">Recharge %</label>
                                <input type="number" step="0.5" min="0" max="100" id="sref-recharge" class="form-control" placeholder="Default: ${glob.recharge_percent ?? 10}%" value="${ov.custom_referral_recharge_percent ?? ''}">
                            </div>
                            <div class="form-group">
                                <label style="font-weight:600;">Max Redeem %</label>
                                <input type="number" step="1" min="0" max="100" id="sref-redeem" class="form-control" placeholder="Default: ${glob.max_redeem_percent ?? 50}%" value="${ov.custom_referral_max_redeem_percent ?? ''}">
                            </div>
                        </div>

                        <div style="font-size:11px; color:#475569; background:#eef2ff; padding:8px 10px; border-radius:6px; margin-top:8px;">
                            <strong>Effective Now:</strong> ${eff.enabled ? 'Enabled' : 'Disabled'} | Mode: ${eff.reward_mode} | Signup: ${eff.signup_points} pts | Recharge: ${eff.recharge_percent}% | Max Redeem: ${eff.max_redeem_percent}%
                        </div>

                        <button type="submit" class="btn-primary" style="width:100%; margin-top:12px; padding:9px; font-weight:600;">Save Shop-Wise Overrides</button>
                    </form>

                    <hr style="margin:18px 0; border:0; border-top:1px solid #e2e8f0;">

                    <form onsubmit="submitShopPointAdjustment(event, ${shopId})">
                        <h4 style="font-size:13px; font-weight:700; color:#0f172a; margin-bottom:8px;">Manual Wallet Adjustment (Credit / Debit Points)</h4>
                        <div style="display:grid; grid-template-columns:130px 120px 1fr; gap:10px;">
                            <select id="sref-adj-type" class="form-control">
                                <option value="credit">+ Credit</option>
                                <option value="debit">- Debit</option>
                            </select>
                            <input type="number" step="1" min="1" id="sref-adj-pts" class="form-control" placeholder="Points" required>
                            <input type="text" id="sref-adj-reason" class="form-control" placeholder="Reason (e.g. Promo bonus)" required>
                        </div>
                        <button type="submit" class="btn-sm" style="width:100%; margin-top:10px; padding:8px; background:#0f172a; color:white; font-weight:600;">Apply Point Adjustment</button>
                    </form>
                </div>
            `, '620px');
        }

        async function saveShopReferralOverrides(e, shopId) {
            e.preventDefault();
            const alertErr = document.getElementById('sref-alert');
            const alertSucc = document.getElementById('sref-success');
            alertErr.style.display = 'none';
            alertSucc.style.display = 'none';

            const enabledStr = document.getElementById('sref-enabled').value;
            const modeStr = document.getElementById('sref-mode').value;
            const signupStr = document.getElementById('sref-signup').value;
            const rechargeStr = document.getElementById('sref-recharge').value;
            const redeemStr = document.getElementById('sref-redeem').value;

            const body = {
                referral_enabled_override: enabledStr === '' ? null : (enabledStr === '1'),
                referral_reward_mode_override: modeStr === '' ? null : modeStr,
                custom_referral_signup_points: signupStr === '' ? null : parseFloat(signupStr),
                custom_referral_recharge_percent: rechargeStr === '' ? null : parseFloat(rechargeStr),
                custom_referral_max_redeem_percent: redeemStr === '' ? null : parseFloat(redeemStr),
            };

            const res = await apiFetch(`/shops/${shopId}/referral-settings`, 'PUT', body);
            if (res && res.success) {
                alertSucc.textContent = 'Shop-wise referral settings updated!';
                alertSucc.style.display = 'block';
                if (currentMainSection === 'referrals') loadReferralsView();
            } else {
                alertErr.textContent = res?.message || 'Failed to update shop-wise settings.';
                alertErr.style.display = 'block';
            }
        }

        async function submitShopPointAdjustment(e, shopId) {
            e.preventDefault();
            const alertErr = document.getElementById('sref-alert');
            const alertSucc = document.getElementById('sref-success');
            alertErr.style.display = 'none';
            alertSucc.style.display = 'none';

            const body = {
                type: document.getElementById('sref-adj-type').value,
                points: parseFloat(document.getElementById('sref-adj-pts').value || 0),
                reason: document.getElementById('sref-adj-reason').value.trim(),
            };

            const res = await apiFetch(`/shops/${shopId}/referral-points`, 'POST', body);
            if (res && res.success) {
                alertSucc.textContent = `Points ${body.type}ed! New balance: ${res.data?.points_balance ?? ''} pts`;
                alertSucc.style.display = 'block';
                setTimeout(() => openShopReferralModal(shopId, ''), 800);
                if (currentMainSection === 'referrals') loadReferralsView();
            } else {
                alertErr.textContent = res?.message || 'Failed to adjust points.';
                alertErr.style.display = 'block';
            }
        }

        // ==================== OTP VERIFICATION SETTINGS ====================
        async function loadOtpSettingsView() {
            const content = getContentContainer();
            content.innerHTML = '<div style="padding:20px; color:#64748b;">Loading OTP settings...</div>';
            const res = await apiFetch('/otp-settings');
            if (!res || !res.success) return;
            const enabled = res.data?.otp_verification_enabled !== false;

            content.innerHTML = `
                <div class="card-table" style="padding:24px; max-width:620px;">
                    <h3 style="font-size:18px; font-weight:700; color:#0f172a; margin:0 0 4px 0;">🔐 OTP Verification (Signup & Forgot Password)</h3>
                    <p style="font-size:13px; color:#64748b; margin:0 0 18px 0;">Turn SMS OTP verification ON for production or OFF to skip OTP during local testing.</p>

                    <div id="otp-alert" class="alert-error" style="display:none;"></div>
                    <div id="otp-success" style="display:none; background:#f0fdf4; border:1px solid #bbf7d0; color:#166534; padding:12px; border-radius:8px; margin-bottom:16px; font-size:13px; font-weight:500;"></div>

                    <form onsubmit="saveOtpSettings(event)">
                        <div class="form-group">
                            <label style="font-weight:600;">OTP Verification Mode</label>
                            <select id="otp-enabled-select" class="form-control" style="font-weight:600;">
                                <option value="1" ${enabled ? 'selected' : ''}>✅ ON — Require SMS OTP for Signup & Forgot Password (Production)</option>
                                <option value="0" ${!enabled ? 'selected' : ''}>⏭️ OFF — Skip OTP (Direct Signup & Password Reset for Local Testing)</option>
                            </select>
                            <small style="color:#64748b; font-size:11px; display:block; margin-top:6px;">
                                When OFF, new shops register immediately and Forgot Password goes straight to Reset Password without sending SMS.
                            </small>
                        </div>

                        <div style="margin-top:20px;">
                            <button type="submit" class="btn-primary" style="width:100%; padding:11px; font-weight:600;">Save OTP Settings</button>
                        </div>
                    </form>
                </div>
            `;
        }

        async function saveOtpSettings(e) {
            e.preventDefault();
            const alertErr = document.getElementById('otp-alert');
            const alertSucc = document.getElementById('otp-success');
            alertErr.style.display = 'none';
            alertSucc.style.display = 'none';

            const enabled = document.getElementById('otp-enabled-select').value === '1';
            const res = await apiFetch('/otp-settings', 'POST', { otp_verification_enabled: enabled });
            if (res && res.success) {
                alertSucc.textContent = res.message || 'OTP settings saved!';
                alertSucc.style.display = 'block';
            } else {
                alertErr.textContent = res?.message || 'Failed to save OTP settings.';
                alertErr.style.display = 'block';
            }
        }
</script>
</body>
</html>
