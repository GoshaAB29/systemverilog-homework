//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_2_pipe
(
    input         clk,
    input         rst,

    input         arg_vld,
    input  [31:0] a,
    input  [31:0] b,
    input  [31:0] c,

    output        res_vld,
    output [31:0] res
);
    // Task:
    //
    // Implement a pipelined module formula_2_pipe that computes the result
    // of the formula defined in the file formula_2_fn.svh.
    //
    // The requirements:
    //
    // 1. The module formula_2_pipe has to be pipelined.
    //
    // It should be able to accept a new set of arguments a, b and c
    // arriving at every clock cycle.
    //
    // It also should be able to produce a new result every clock cycle
    // with a fixed latency after accepting the arguments.
    //
    // 2. Your solution should instantiate exactly 3 instances
    // of a pipelined isqrt module, which computes the integer square root.
    //
    // 3. Your solution should save dynamic power by properly connecting
    // the valid bits.
    //
    // You can read the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm
    
    logic [31:0] res_a;
    logic [31:0] res_b;
    logic [31:0] res_c;
    
    logic vld_c;
    logic vld_c_ff;
    logic vld_b;
    logic vld_b_ff;
    
    logic [31:0] res_bc;
    logic [31:0] res_abc;
    
    logic [31:0] shift_b [0:15];
    logic [31:0] shift_a [0:32];
    
    
       isqrt sqrt1
    (
        .clk   ( clk           ),
        .rst   ( rst           ),

        .x_vld ( arg_vld       ),
        .x     ( c             ),

        .y_vld ( vld_c         ),
        .y     ( res_c         )
    );
    
    isqrt sqrt2
    (
        .clk   ( clk           ),
        .rst   ( rst           ),

        .x_vld ( vld_c_ff      ),
        .x     ( res_bc        ),

        .y_vld ( vld_b         ),
        .y     ( res_b         )
    );
    
    isqrt sqrt3
    (
        .clk   ( clk           ), 
        .rst   ( rst           ), 
        
        .x_vld ( vld_b_ff      ),
        .x     ( res_abc       ),
        
        .y_vld ( vld_a         ),
        .y     ( res_a         )
    );



    always_ff @(posedge clk)               //shift b
    begin
    shift_b[0] <= b;
    for (int i = 1; i < 16; i++)
        shift_b[i] <= shift_b[i - 1];
    end


    always_ff @(posedge clk)               //shift a
    begin
    shift_a[0] <= a;
    for (int i = 1; i < 33; i++)
        shift_a[i] <= shift_a[i - 1];
    end


    always_ff @(posedge clk)               //sqrt(c)
    if (rst)
        vld_c_ff <= 1'b0;
    else
        vld_c_ff <= vld_c;


    always_ff @(posedge clk)               //b + sqrt(c)
    if (vld_c)
        res_bc <= res_c + shift_b[15];


    always_ff @(posedge clk)               //sqrt(b + sqrt(c))
    if (rst)
        vld_b_ff <= 1'b0;
    else
        vld_b_ff <= vld_b;


    always_ff @(posedge clk)               //a + sqrt(b + sqrt(c))
    if (vld_b)
        res_abc <= res_b + shift_a[32];
        
        
    assign res_vld = vld_a;  
    assign res     = res_a;                //finally: sqrt(a + sqrt(b + sqrt(c)))
    
endmodule
