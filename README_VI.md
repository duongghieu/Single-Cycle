# Hướng dẫn kiểm chứng ARM Single-Cycle

Tài liệu này hướng dẫn chạy các file đang có trong repo [duongghieu/Single-Cycle](https://github.com/duongghieu/Single-Cycle).
Cấu trúc và lệnh chạy được đối chiếu với commit `e19d857f9b3e9d16beac5d22e64f1537585b6396`.

## 1. Chọn bộ test cần chạy

| Bộ test | Script | Chương trình CPU | Mục đích |
| --- | --- | --- | --- |
| Kiểm chứng chính | `run_reference.do` | `tests/reference/program.dat` | Kiểm tra đủ 7 loại lệnh, đối chiếu Reference Model và Scoreboard, thu coverage |
| Chương trình mẫu | `run_top.do` | `mem.dat` | Kiểm tra ADD, SUB, AND, ORR, LSL/LSR, vòng dừng B . và reset/chạy lại |

Dùng **`run_reference.do`** để chạy bộ kiểm chứng chính phục vụ project. Không cần chạy `run_top.do` trước.
LSL/LSR và B . trong chương trình mẫu không thay thế các test LDR/STR và BEQ của đề.

## 2. Chuẩn bị dự án

1. Tải hoặc clone toàn bộ repo, giữ nguyên cấu trúc thư mục.
2. Dùng ModelSim Intel FPGA; phiên bản đề yêu cầu là 10.5b.
3. Xác định thư mục chứa đồng thời `top.sv`, `run_reference.do` và thư mục `tests`.
4. Giữ nguyên `mem.dat` để tiếp tục chạy được chương trình mẫu. Bộ reference dùng một ROM riêng, được chọn qua parameter `MEMFILE` trong testbench.

Các file verification chỉ dùng để mô phỏng. Không thêm chúng vào danh sách RTL tổng hợp của Quartus. Việc chạy các test này không yêu cầu nạp kit hoặc gán chân FPGA.

## 3. Chạy bộ kiểm chứng chính trong ModelSim

Mở ModelSim và nhập vào **Transcript**, thay đường dẫn bên dưới bằng thư mục dự án của bạn:

```tcl
do {D:/Cuoi ki TKS/Single-Cycle-main/Single-Cycle-main/run_reference.do}
```

Dùng dấu `/` trong đường dẫn Windows và giữ cặp dấu `{ }` nếu tên thư mục có khoảng trắng.
Script tự chuyển về thư mục chứa nó, biên dịch RTL và verification, mở `tb_reference`, ghi waveform rồi chạy đến khi testbench kết thúc.

Script sẽ:

1. Biên dịch RTL CPU và ba file `reference_model.sv`, `scoreboard.sv`, `tb_reference.sv`.
2. Nạp chương trình từ `tests/reference/program.dat`.
3. Reset CPU, chạy chương trình và so sánh từng lệnh.
4. Reset lần nữa, kiểm tra RAM được giữ nguyên rồi chạy lại chương trình.
5. Kiểm tra các bộ đếm coverage và in kết quả cuối cùng.

### Kết quả PASS

Với nguyên bộ test hiện tại, cuối Transcript cần có:

```text
EPOCH 1 PASSED
EPOCH 2 PASSED
...
ALL REFERENCE TESTS PASSED (104 instructions, 29680 checks)
```

Chỉ kết luận PASS khi có dòng cuối cùng và không có lỗi hoặc `$fatal` trước đó. Một cửa sổ Wave có tín hiệu chưa đủ để kết luận test đã đạt.

`104 instructions` là tổng số lượt lệnh qua hai lần chạy, mỗi lần 52 lượt. Số này bao gồm các lệnh được xét nhưng không thực hiện do điều kiện sai. `29680 checks` là số phép so sánh, không phải phần trăm coverage.
Nếu sửa chương trình hoặc thêm phép kiểm tra, các con số này có thể thay đổi.

### Kết quả FAIL

Khi có sai khác, Scoreboard dừng bằng `$fatal`, ví dụ:

```text
FAIL cycle=2 PC=00000008 instr=e5902000 R2 expected=00000019 actual=00000000
```

Ví dụ này có nghĩa: tại PC `0x08`, R2 cần bằng `0x19` (25 thập phân), nhưng DUT trả về 0. Cycle đếm từ 0; PC, instruction, expected và actual được in theo hệ hexadecimal.
Đây là ví dụ cách đọc lỗi, không phải lỗi được khẳng định đang tồn tại trong CPU.

## 4. Các file kết quả được tạo khi chạy

Các file dưới đây được sinh tại thư mục chứa `top.sv`; chúng không phải các file nguồn đã có sẵn trong repo.

| File | Thành phần tạo | Nội dung |
| --- | --- | --- |
| `reference_modelsim.log` | `run_reference.do` | Transcript gồm biên dịch, thông báo kiểm tra và PASS/FAIL |
| `reference_trace.csv` | Scoreboard | PC, lệnh, PC tiếp theo và NZCV kỳ vọng sau từng lệnh |
| `reference_coverage.csv` | Testbench | Bộ đếm các tình huống kiểm thử |
| `reference_wave.wlf` | ModelSim | Dữ liệu waveform để mở lại trong ModelSim |

`reference_trace.csv` chứa trạng thái kỳ vọng từ model; kết quả DUT được so sánh trực tiếp trong Scoreboard. Một trace kỳ vọng riêng lẻ không chứng minh DUT đã PASS.

Các lần chạy lại có thể ghi lại kết quả cùng tên. Sau một lần PASS, sao chép log, trace, coverage và waveform sang thư mục riêng để giữ bằng chứng. Khi test dừng sớm vì lỗi, file coverage có thể chưa được tạo mới; không dùng file còn sót từ lần chạy trước để kết luận cho lần chạy hiện tại.

Repo hiện không có thư mục `evidence/` hoặc script `run_reference_iverilog.sh`. Các bước chạy ModelSim trong tài liệu này không phụ thuộc vào hai mục đó.

## 5. Các file nguồn và vai trò

| File hoặc nhóm file | Vai trò |
| --- | --- |
| `top.sv`, `datapath.sv`, `Controlunit/` và các khối RTL ở thư mục gốc | CPU DUT được kiểm chứng |
| `tests/reference/tb_reference.sv` | Driver, Monitor, điều phối so sánh trước/sau cạnh clock, reset/chạy lại và coverage |
| `tests/reference/reference_model.sv` | Mô hình kiến trúc độc lập bằng SystemVerilog, giữ PC, thanh ghi, cờ và RAM kỳ vọng |
| `tests/reference/scoreboard.sv` | So sánh bằng `!==`, báo sai khác và ghi trace |
| `tests/reference/program.dat` | 64 word ROM, gồm chương trình và các word đệm |
| `tests/reference/program.asm` | Diễn giải chương trình, có địa chỉ và mã máy tương ứng |
| `tests/reference/test_plan.csv` | 27 kịch bản, kết quả kỳ vọng và tín hiệu quan sát |
| `run_reference.do` | Điểm bắt đầu để chạy bộ kiểm chứng chính trên ModelSim |
| `tb_top.sv`, `mem.dat`, `run_top.do` | Bộ test chương trình mẫu |

Driver và Monitor đang nằm trong `tb_reference.sv`; không cần có file riêng tên `driver.sv` hoặc `monitor.sv` để chạy bộ test.

Reference Model đọc bản riêng của cùng chương trình, tự giải mã và cập nhật trạng thái. Model không dùng PC, kết quả ALU, cờ hay dữ liệu RAM từ DUT làm đáp án. Testbench/Scoreboard đọc DUT để so sánh với trạng thái đó.

## 6. Thời điểm so sánh

- **Trước cạnh lên:** model tính đáp án; testbench so sánh PC/lệnh, RegWrite, MemWrite, PCSrc và giao tiếp bộ nhớ khi có LDR/STR thực hiện.
- **Sau cạnh lên 1 ns:** so sánh PC mới, NZCV, toàn bộ R0–R14 và tất cả 256 word RAM. Khoảng chờ giúp các phép gán nonblocking hoàn tất trước khi đọc kết quả.
- **Cuối mỗi lượt:** kiểm tra thêm các giá trị thanh ghi/RAM được tính trước để kiểm tra chéo model và chương trình.

Các quy ước của dự án:

- R0 là thanh ghi thông thường; chương trình reference dùng giá trị 0 của R0 sau reset và không ghi lại R0.
- Đọc R15 trả PC+8. Khi ghi PC, thiết kế bỏ hai bit địa chỉ thấp.
- RAM có 256 word 32 bit; địa chỉ byte hợp lệ, thẳng hàng là 0, 4, ..., 1020.
- RAM không bị xóa khi reset. Các ô chưa ghi giữ X trong mô phỏng; chương trình không đọc hợp lệ từ ô chưa được ghi.
- Địa chỉ RAM không thẳng hàng hoặc ngoài vùng: ghi bị bỏ qua, đọc trả 0. Đây là quy ước của CPU bài thực hành, không phải mô hình exception của ARM đầy đủ.
- BEQ dựa trên cờ Z đã lưu. Chương trình dùng SUBS để tạo điều kiện trước khi kiểm tra nhánh.

## 7. Phạm vi test và coverage hiện tại

Bộ reference kiểm tra ADD, SUB, AND, ORR, LDR, STR và BEQ taken/not-taken trong một chương trình tích hợp, gồm:

- Ghi/đọc/ghi đè RAM, đọc dữ liệu 0 vào thanh ghi đang khác 0.
- Các địa chỉ byte 0, 4, 12 và 1020; bỏ qua ghi và trả 0 khi đọc địa chỉ không hợp lệ.
- Điều kiện cho phép/bỏ qua ghi thanh ghi hoặc ghi RAM.
- Cộng có carry, cộng/trừ có overflow, trừ hai toán hạng bằng nhau, giữ cờ khi S=0 và giữ V cho phép logic.
- Một số trường hợp logic cho kết quả toàn 0/toàn 1, PC+8, ghi PC, nhánh lùi và reset/chạy lại.

Trong lần kiểm tra bằng Icarus Verilog 11.0, bộ reference đạt:

```text
ALL REFERENCE TESTS PASSED (104 instructions, 29680 checks)
```

Các bộ đếm chính trong lần chạy đó:

| Trường hợp | Số lượt |
| --- | ---: |
| ADD | 30 |
| SUB | 14 |
| AND | 6 |
| ORR | 8 |
| LDR | 14 |
| STR | 16 |
| BEQ taken | 4 |
| BEQ not-taken | 4 |

Số lượt LDR/STR bao gồm các test chính sách địa chỉ không hợp lệ. Coverage hiện tại là các bộ đếm tình huống được viết trong testbench, không phải line/toggle coverage của công cụ và không chứng minh đã kiểm tra mọi tổ hợp đầu vào.

**Giới hạn còn lại:** chưa có các test AND/OR dùng mẫu bit xen kẽ `0xAAAAAAAA`/`0x55555555`; chưa có test ADD với hai toán hạng bằng nhau. Chưa được xác nhận chạy bằng ModelSim 10.5b trong môi trường kiểm tra tài liệu này. Các chức năng mở rộng như MOV, EOR và các kiểu dịch không được bộ reference hiện tại bao phủ đầy đủ.

Để hoàn thiện bộ bàn giao theo đề, cần bổ sung test còn thiếu, lấy bằng chứng chạy thực tế trên ModelSim và kèm báo cáo phân tích kiến trúc cùng tổng kết kiểm thử/debug/giới hạn.

## 8. Chạy chương trình mẫu nếu cần

Nếu đang mở một mô phỏng khác, kết thúc nó bằng `quit -sim` trước khi chạy bộ mẫu. Sau đó nhập:

```tcl
do {D:/Cuoi ki TKS/Single-Cycle-main/Single-Cycle-main/run_top.do}
```

Thay đường dẫn theo thư mục thực tế. Với `mem.dat` và `tb_top.sv` hiện tại, kết quả kiểm tra bằng Icarus là:

```text
ALL TESTS PASSED (754 checks)
```

Bộ mẫu dùng `mem.dat`; bộ reference dùng `tests/reference/program.dat`. Đừng thay một file ROM rồi dùng testbench của chương trình khác để đánh giá kết quả.

## 9. Xử lý lỗi thường gặp

| Hiện tượng | Cách kiểm tra |
| --- | --- |
| `vlog failed`, `Error loading design` | Đọc lỗi biên dịch đầu tiên trong Transcript, kiểm tra đủ file và đúng tên module; thông báo cuối chỉ cho biết mô phỏng chưa nạp được |
| Không tìm thấy `top.sv` hoặc file chương trình | Giữ script cạnh `top.sv`, giữ nguyên `tests/reference/`, gọi script bằng đường dẫn thực tế |
| `Unrecognized dataset prefix: sim` | Thiết kế chưa được nạp thành công; sửa lỗi biên dịch/nạp trước khi thêm waveform |
| Scoreboard báo khác instruction/PC | Kiểm tra parameter MEMFILE và nội dung ROM; bộ reference phải dùng chương trình reference tương ứng |
| RAM có X | Ô RAM chưa ghi có thể là X theo thiết kế; xem địa chỉ và kiểm tra có ghi trước khi đọc hợp lệ hay chưa |
| Wave dùng hexadecimal khó đọc | Ví dụ `00000019` là 25 và `0000005A` là 90; đổi radix sang unsigned nếu cần xem số thập phân |
| Không có dòng PASS cuối | Kiểm tra `$fatal`, lỗi biên dịch hoặc timeout; không coi file coverage cũ là kết quả của lần chạy này |
