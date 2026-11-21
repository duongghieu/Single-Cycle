# ARM Single-Cycle Verification

Dự án CPU ARM Single-Cycle và môi trường kiểm chứng bằng SystemVerilog.

## Chạy bộ kiểm chứng chính

Trong Transcript của ModelSim Intel FPGA, nhập đường dẫn tới script:

```tcl
do {D:/duong_dan/Single-Cycle/run_reference.do}
```

Thay đường dẫn bằng thư mục chứa `top.sv` và giữ nguyên `tests/reference/`.
Bộ test dùng `tests/reference/program.dat`, có Reference Model độc lập,
Scoreboard tự động PASS/FAIL, kiểm tra đủ bảy loại lệnh và BEQ taken/not-taken.

Xem **[hướng dẫn tiếng Việt](README_VI.md)** để biết cấu trúc file,
cách đọc log/waveform, phạm vi kiểm tra và giới hạn còn lại.
Xem [Test Plan](tests/reference/test_plan.csv) và
[chương trình kiểm thử](tests/reference/program.asm).

Kết quả đã kiểm tra bằng Icarus Verilog 11.0:

```text
ALL REFERENCE TESTS PASSED (104 instructions, 29680 checks)
```

Chưa xác nhận chạy bằng ModelSim 10.5b trong môi trường kiểm tra này.
Log và waveform ModelSim được tạo khi chạy `run_reference.do` trên máy người dùng;
chúng không được cung cấp sẵn trong repo. Xem giới hạn test trong hướng dẫn
trước khi kết luận đã hoàn thành toàn bộ yêu cầu cuối kỳ.

Chương trình mẫu cũ vẫn chạy riêng bằng `run_top.do`, dùng `mem.dat`.
