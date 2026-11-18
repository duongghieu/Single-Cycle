module datamem (
    input  logic        clk,
    input  logic        WE,
    input  logic [31:0] A,
    input  logic [31:0] WD,

    output logic [31:0] ReadData
);

    logic [31:0] ram [0:255];
    logic AddressValid;

    // Dia chi trong RAM va chia het cho 4
    assign AddressValid = (A[31:10] == 0)
                       && (A[1:0] == 0);

    always_ff @(posedge clk) begin
        if (WE && AddressValid)
            ram[A[9:2]] <= WD;
    end

    always_comb begin
        ReadData = AddressValid
                 ? ram[A[9:2]]
                 : 32'b0;
    end

    // RAM khong reset: chuong trinh phai ghi truoc khi doc

endmodule