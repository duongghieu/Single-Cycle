module mux #(
    parameter integer N = 32
) (
    input  logic [N-1:0] a,
    input  logic [N-1:0] b,
    input  logic         sel,

    output logic [N-1:0] y
);

    assign y = sel ? b : a;

endmodule