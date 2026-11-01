#define WIN32_LEAN_AND_MEAN
#define _WIN32_WINNT 0x0601
#define UNICODE
#define _UNICODE
#include <windows.h>
#include <shellapi.h>
#include <shlobj.h>
#include <objbase.h>

static LRESULT CALLBACK NotifyWndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

static void show_toast(HINSTANCE hInst, const wchar_t *title, const wchar_t *text)
{
    static const wchar_t kClassName[] = L"EmptyRecycleBinToast";

    WNDCLASSW wc = { 0 };
    wc.lpfnWndProc = NotifyWndProc;
    wc.hInstance = hInst;
    wc.lpszClassName = kClassName;
    RegisterClassW(&wc);

    HWND hwnd = CreateWindowExW(0, kClassName, L"", WS_POPUP, 0, 0, 0, 0,
                                NULL, NULL, hInst, NULL);
    if (!hwnd)
        return;

    NOTIFYICONDATAW nid = { 0 };
    nid.cbSize = sizeof(nid);
    nid.hWnd = hwnd;
    nid.uID = 1;
    nid.uFlags = NIF_ICON | NIF_TIP | NIF_INFO;
    nid.hIcon = (HICON)LoadImageW(hInst, MAKEINTRESOURCEW(1), IMAGE_ICON,
                                  GetSystemMetrics(SM_CXSMICON), GetSystemMetrics(SM_CYSMICON), 0);
    if (!nid.hIcon)
        nid.hIcon = LoadIconW(NULL, IDI_INFORMATION);
    nid.hBalloonIcon = (HICON)LoadImageW(hInst, MAKEINTRESOURCEW(1), IMAGE_ICON,
                                         GetSystemMetrics(SM_CXICON), GetSystemMetrics(SM_CYICON), 0);
    nid.dwInfoFlags = nid.hBalloonIcon ? (NIIF_USER | NIIF_LARGE_ICON) : NIIF_INFO;
    lstrcpynW(nid.szTip, title, ARRAYSIZE(nid.szTip));
    lstrcpynW(nid.szInfoTitle, title, ARRAYSIZE(nid.szInfoTitle));
    lstrcpynW(nid.szInfo, text, ARRAYSIZE(nid.szInfo));

    if (Shell_NotifyIconW(NIM_ADD, &nid))
    {
        // 保持进程存活片刻，确保通知完整弹出后再撤掉临时托盘图标
        Sleep(6000);
        Shell_NotifyIconW(NIM_DELETE, &nid);
    }

    DestroyWindow(hwnd);
    UnregisterClassW(kClassName, hInst);
}

static void format_size(LONGLONG bytes, wchar_t *buf)
{
    static const wchar_t *const units[] = { L"B", L"KB", L"MB", L"GB", L"TB" };
    LONGLONG unit = 1;
    int i = 0;
    while (i < 4 && bytes >= unit * 1024)
    {
        unit *= 1024;
        i++;
    }
    if (i == 0)
        wsprintfW(buf, L"%d B", (int)bytes);
    else
    {
        LONGLONG tenths = (bytes * 10 + unit / 2) / unit;
        wsprintfW(buf, L"%d.%d %s", (int)(tenths / 10), (int)(tenths % 10), units[i]);
    }
}

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int nCmdShow)
{
    (void)hPrevInstance; (void)lpCmdLine; (void)nCmdShow;

    HRESULT hrCom = CoInitializeEx(NULL, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);

    // 回收站为空时 SHEmptyRecycleBinW 会返回 E_UNEXPECTED，需先判空
    SHQUERYRBINFO info = { sizeof(info) };
    BOOL queried = SUCCEEDED(SHQueryRecycleBinW(NULL, &info));
    BOOL binEmpty = queried && info.i64NumItems == 0;

    HRESULT hr = S_OK;
    if (binEmpty)
        show_toast(hInstance, L"清空回收站", L"回收站本来就是空的。");
    else
    {
        hr = SHEmptyRecycleBinW(NULL, NULL,
                                SHERB_NOCONFIRMATION | SHERB_NOPROGRESSUI | SHERB_NOSOUND);
        if (hr == S_OK)
        {
            wchar_t text[128];
            if (queried && info.i64Size > 0)
            {
                wchar_t size[64];
                format_size(info.i64Size, size);
                wsprintfW(text, L"回收站已清空，共清理 %s 垃圾。", size);
            }
            else
                lstrcpyW(text, L"回收站已清空。");
            show_toast(hInstance, L"清空回收站", text);
        }
        else if (hr == S_FALSE)
            show_toast(hInstance, L"清空回收站", L"回收站本来就是空的。");
        else
        {
            wchar_t text[128];
            wsprintfW(text, L"清空回收站失败（错误码 0x%08X）。", (unsigned int)hr);
            show_toast(hInstance, L"清空回收站", text);
        }
    }

    if (SUCCEEDED(hrCom))
        CoUninitialize();

    return FAILED(hr) ? 1 : 0;
}
