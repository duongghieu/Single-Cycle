# Bổ sung Reference Model và Scoreboard cho Single-Cycle

## Cách thêm vào dự án

Đây là gói bổ sung cho repo https://github.com/duongghieu/Single-Cycle,
đối chiếu tại commit `620034ffb324891b983357718ee91b3c056deba9`.
Gói không chứa lại RTL CPU. Các tên module và đường dẫn quan sát đã khớp
với bản repo này. Nếu bạn đổi tên module hoặc instance sau đó, cần sửa lại
đường dẫn trong testbench và danh sách biên dịch trong script.

1. Giải nén gói này.
2. Chép `run_reference.do` và toàn bộ thư mục `tests/reference` vào thư mục
   dự án đang chứa `top.sv`. Giữ nguyên cấu trúc bên trong thư mục `tests`.
3. Mở ModelSim, nhập ở Transcript (thay đường dẫn bằng thư mục của bạn):

```tcl
do {D:/Cuoi ki TKS/Single-Cycle-main/Single-Cycle-main/run_reference.do}
```

Không thêm các file này vào danh sách RTL tổng hợp của Quartus. Chúng chỉ
dùng để mô phỏng. Không cần sửa `mem.dat` hoặc chạy `run_top.do` trước.
Script này tự biên dịch RTL hiện tại và dùng chương trình `program.dat` riêng.
Nếu dự án đã có thư mục `tests/memory`, chỉ bổ sung `tests/reference` bên cạnh.

## Các file chính

| File | Nhiệm vụ |
| --- | --- |
| `tests/reference/reference_model.sv` | Tự giải mã lệnh, tính PC, thanh ghi, cờ và RAM kỳ vọng bằng SystemVerilog |
| `tests/reference/scoreboard.sv` | So sánh bằng `!==`, báo lỗi kèm PC/lệnh/expected/actual; ghi trace CSV |
| `tests/reference/tb_reference.sv` | Tạo clock/reset, ghép DUT với model, so sánh từng lệnh, thu coverage |
| `tests/reference/program.dat` | 64 word ROM: 53 vị trí chương trình và các word đệm |
| `tests/reference/program.asm` | Bản dễ đọc của chương trình, kèm địa chỉ và mã máy |
| `run_reference.do` | Biên dịch, chạy, mở waveform và ghi log trong ModelSim |
| `run_reference_iverilog.sh` | Script chạy bằng Icarus trên Linux/macOS, tùy chọn |
| `tests/reference/test_plan.csv` | Các mục tiêu kiểm tra và kết quả mong đợi |
| `evidence/` | Log, trace, coverage và kết quả chèn lỗi từ lần chạy kiểm tra đi kèm |

Reference Model không nhận PC, cờ, kết quả ALU hay dữ liệu RAM từ DUT để tính
đáp án. Nó đọc một bản riêng của cùng file chương trình, giữ trạng thái riêng
và tính kết quả theo ý nghĩa lệnh. Chỉ testbench/scoreboard đọc tín hiệu DUT
để so sánh. Ngoài kết quả từ model, testbench có các giá trị cuối chương trình
đã tính trước để kiểm tra chéo chương trình và model.

## Khi nào so sánh?

Trước cạnh lên, model tính lệnh kế tiếp và testbench kiểm tra PC/lệnh cùng
các tín hiệu cho phép ghi, chọn PC và giao tiếp bộ nhớ. Sau cạnh lên 1 ns,
testbench kiểm tra PC mới, toàn bộ R0–R14, NZCV và tất cả 256 word RAM.
Khoảng chờ này tránh đọc trạng thái cũ trước khi phép gán nonblocking hoàn tất.

R0 là thanh ghi thông thường, không phải thanh ghi luôn bằng 0. Chương trình
này dùng giá trị 0 của R0 sau reset và không ghi lại R0. R15 khi đọc là PC+8;
khi ghi PC, hai bit địa chỉ thấp được bỏ theo thiết kế hiện tại.

RAM không bị reset. Model giữ RAM qua lần reset thứ hai và scoreboard kiểm
tra nội dung đó ngay trong reset. Các ô chưa được ghi là X trong mô phỏng
4 trạng thái; chương trình không đọc hợp lệ từ ô chưa ghi. Không khởi tạo
RAM DUT bằng cách ép hoặc ghi trực tiếp trong testbench.

## Kết quả chạy đúng

Cuối Transcript phải có:

```text
EPOCH 1 PASSED
EPOCH 2 PASSED
...
ALL REFERENCE TESTS PASSED (104 instructions, 29680 checks)
```

Chương trình chạy 2 lần, mỗi lần 52 lượt thực hiện lệnh. Một số lệnh bị bỏ qua
bởi nhánh và vòng lặp làm một số lệnh được thực hiện nhiều lần, nên số lượt
không bằng số vị trí mã lệnh trong ROM.

Script tạo các file tại thư mục dự án:

| File sinh ra | Nội dung |
| --- | --- |
| `reference_modelsim.log` | Transcript của lần chạy ModelSim trên máy bạn |
| `reference_trace.csv` | PC, mã lệnh, PC kế tiếp và cờ kỳ vọng sau mỗi lệnh |
| `reference_coverage.csv` | Số lần đạt từng tình huống đã định nghĩa |
| `reference_wave.wlf` | Waveform ModelSim |

`reference_trace.csv` là trace của model; kết quả DUT được đối chiếu trực tiếp
trong scoreboard. Chỉ xem một trace kỳ vọng không đủ để kết luận PASS; phải
có thông báo PASS cuối log và không có `$fatal`.

Nếu sai, mô phỏng dừng và báo dạng:

```text
FAIL cycle=2 PC=00000008 instr=e5902000 R2 expected=00000019 actual=00000000
```

Các số PC/instruction/expected/actual trong thông báo này ở hệ hexadecimal.
`00000019` tương ứng 25 ở hệ thập phân. Cycle được đếm từ 0.

## Phạm vi và kiểm tra thực tế

- Đã chạy PASS với RTL gốc ở commit nêu trên bằng Icarus Verilog 11.0,
  mô phỏng 4 trạng thái. Chưa chạy ModelSim 10.5b trong môi trường tạo gói.
- Kiểm tra ADD, SUB, AND, ORR, LDR, STR, BEQ taken/not-taken; thêm điều kiện
  bỏ qua lệnh, PC+8, ghi PC, nhánh lùi, carry/overflow, số 0, toàn bit 1,
  đọc/ghi/ghi đè RAM, địa chỉ 0/4/12/1020 và reset giữ RAM.
- Với địa chỉ RAM không thẳng hàng hoặc ngoài vùng 0..1023, thiết kế hiện tại
  bỏ qua ghi và trả 0 khi đọc. Đây là quy ước của dự án, không phải cơ chế
  exception của một CPU ARM đầy đủ.
- Model còn giải mã MOV, EOR và các kiểu dịch immediate của dự án, nhưng
  chương trình đi kèm không chứng minh đầy đủ các chức năng mở rộng này.
  Lệnh ngoài tập hỗ trợ làm model báo lỗi thay vì tự coi là NOP.
- Coverage đi kèm là bộ đếm tình huống trong testbench, không phải báo cáo
  line/toggle/branch coverage của công cụ, không phải khẳng định CPU đã được
  kiểm chứng hoàn toàn hay hoàn thành mọi tiêu chí của đề.
- Đã chèn riêng 6 lỗi vào bản RTL thử nghiệm; scoreboard phát hiện đủ 6/6.
  Các lỗi chèn không nằm trong file gửi và không sửa repo gốc.
- Repo gốc có literal `3'b0110` tại phần ORR của `ALU_Decoder.sv`, gây cảnh báo
  độ rộng; giá trị sau cắt vẫn là `3'b110`. Có thể sửa cách viết thành
  `3'b110` để hết cảnh báo; việc chạy bộ test này không phụ thuộc sửa đó.

## Chạy bằng Icarus nếu cần

Chép thêm `run_reference_iverilog.sh` cạnh `top.sv`. Khi đã cài `iverilog`
và `vvp`, chạy tại terminal:

```bash
bash run_reference_iverilog.sh
```

Muốn xuất thêm VCD:

```bash
bash run_reference_iverilog.sh +DUMP_VCD
```

Log Icarus lưu trong `reference_icarus.log`. Để lấy bằng chứng nộp bài từ
ModelSim, chạy script `.do` trên máy của bạn rồi dùng log và waveform mới.
