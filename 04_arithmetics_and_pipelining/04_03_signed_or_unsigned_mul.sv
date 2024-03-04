//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

// A non-parameterized module
// that implements the signed multiplication of 4-bit numbers
// which produces 8-bit result

module signed_mul_4
(
  input  signed [3:0] a, b,
  output signed [7:0] res
);

  assign res = a * b;

endmodule

// A parameterized module
// that implements the unsigned multiplication of N-bit numbers
// which produces 2N-bit result

module unsigned_mul
# (
  parameter n = 8
)
(
  input  [    n - 1:0] a, b,
  output [2 * n - 1:0] res
);

  assign res = a * b;

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

// Task:
//
// Implement a parameterized module
// that produces either signed or unsigned result
// of the multiplication depending on the 'signed_mul' input bit.

module signed_or_unsigned_mul
# (
  parameter n = 8
)
(
  input  [    n - 1:0] a, b,
  input                signed_mul,
  output [2 * n - 1:0] res
);

  logic [    n - 1:0] abs_a, abs_b;
  logic [2 * n - 1:0] unsigned_res, signed_res, abs_mul;
  logic signed_minus;
  logic sign_a, sign_b;
  
  assign sign_a = a[n - 1];
  assign sign_b = b[n - 1];

  always_comb
  begin
    signed_minus = (a != n'(0)) & (b != n'(0))? sign_a ^ sign_b : 0;
    
    abs_a = (sign_a)? (~a + n'(1)) : a;
    abs_b = (sign_b)? (~b + n'(1)) : b;
    
    abs_mul = abs_a * abs_b;                                                               
  end
  
  assign signed_res = signed_minus? {signed_minus, ~abs_mul[2 * n - 2:0] + n'(1)}
                                  : {signed_minus,  abs_mul[2 * n - 2:0]};
  assign unsigned_res = a * b;  

  assign res = signed_mul? signed_res : unsigned_res;

endmodule

//----------------------------------------------------------------------------
// Testbench
//----------------------------------------------------------------------------

module testbench;

  localparam n = 4;

  logic          [    n - 1:0] a, b;
  logic                        signed_mul;
  logic          [2 * n - 1:0] res;

  logic   signed [    n - 1:0] sa, sb;
  logic   signed [2 * n - 1:0] sres;

  logic unsigned [2 * n - 1:0] t_res;
  logic   signed [2 * n - 1:0] t_sres;

  signed_mul_4 i_signed_mul_4
    (.a (a), .b (b), .res (t_sres));

  unsigned_mul #(n) i_unsigned_mul
    (.a (a), .b (b), .res (t_res));

  signed_or_unsigned_mul #(.n (n)) i_signed_or_unsigned_mul
    (.a (a), .b (b), .signed_mul (signed_mul), .res (res));

  task test
    (
      input [n - 1:0] t_a, t_b,
      input t_signed_mul
    );

    { a, b, signed_mul } = { t_a, t_b, t_signed_mul };

    # 1;

    { sa, sb, sres } = { a, b, res };

    if (signed_mul)
    begin
      $display ("TEST   signed %d * %d = %d", sa, sb, sres);

      if (sres !== t_sres)
      begin
        $display ("%s FAIL: %d EXPECTED", `__FILE__, t_sres);
        $finish;
      end
    end
    else
    begin
      $display ("TEST unsigned %d * %d = %d", a, b, res);

      if (res !== t_res)
      begin
        $display ("%s FAIL: %d EXPECTED", `__FILE__, t_res);
        $finish;
      end
    end

  endtask

  localparam signed [n - 1:0] smin = 1'b1 << (n - 1);
  localparam signed [n - 1:0] smax = ~ smin;
  localparam        [n - 1:0] umax = ~ { n { 1'b0 } };

  initial
    begin
      for (int i = 0; i <= umax; i ++)
      for (int j = 0; j <= umax; j ++)
        test (i, j, 0);

      for (int i = smin; i <= smax; i ++)
      for (int j = smin; j <= smax; j ++)
        test (i, j, 1);

      $display ("%s PASS", `__FILE__);
      $finish;
    end

endmodule
