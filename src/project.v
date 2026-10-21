`default_nettype none


module tt_um_vga_example(
  input  wire [7:0] ui_in,    // Dedicated inputs
  output wire [7:0] uo_out,   // Dedicated outputs
  input  wire [7:0] uio_in,   // IOs: Input path
  output wire [7:0] uio_out,  // IOs: Output path
  output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
  input  wire       ena,      // always 1 when the design is powered, so you can ignore it
  input  wire       clk,      // clock
  input  wire       rst_n     // reset_n - low to reset
);


  // VGA signals
  wire hsync;
  wire vsync;
  reg [1:0] R;
  reg [1:0] G;
  reg [1:0] B;
  wire video_active;
  wire [9:0] pix_x;
  wire [9:0] pix_y;


  // TinyVGA PMOD
  assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};


  // Unused outputs assigned to 0.
  assign uio_out = 0;
  assign uio_oe  = 0;


  // Suppress unused signals warning
  wire _unused_ok = &{ena, ui_in, uio_in};


  hvsync_generator hvsync_gen(
    .clk(clk),
    .reset(~rst_n),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(video_active),
    .hpos(pix_x),
    .vpos(pix_y)
  );


  wire inside_board = video_active && pix_y > 40 && pix_y <= 440 && pix_x > 120 && pix_x <= 520;
 
  // starting point of the grid is (121, 41), so we need relative coordinates from that point
  wire [9:0] rel_x = pix_x - 121;
  wire [9:0] rel_y = pix_y - 41;


  // get row and column number based on the relative coordinates
  wire [1:0] row = rel_x / 100;
  wire [1:0] col = rel_y / 100;


  // get x and y positions within each cell of the grid
  wire [6:0] cell_x = rel_x % 100;
  wire [6:0] cell_y = rel_y % 100;


  wire center = cell_x > 48 && cell_x < 52 && cell_y > 48 && cell_y < 52;


  function automatic [5:0] get_colour;
    input [1:0] r, c;
    begin
      case (grid[r][c])
        4'h0: get_colour = center ? 6'hFF : 6'b01_01_01; // Empty:  Dark Gray / Board BG
        4'h1: get_colour = 6'b11_00_00; // 2:      Red
        4'h2: get_colour = 6'b00_10_00; // 4:      Green
        4'h3: get_colour = 6'b11_11_01; // 8:      Yellow (Red + Green)
        4'h4: get_colour = 6'b00_00_11; // 16:     Pure Blue
        4'h5: get_colour = 6'b10_01_11; // 32:     Magenta / Purple (Red + Blue)
        4'h6: get_colour = 6'b00_11_11; // 64:     Cyan (Green + Blue)
        4'h7: get_colour = 6'b11_01_01; // 128:    Soft Red
        4'h8: get_colour = 6'b01_11_01; // 256:    Soft Green
        4'h9: get_colour = 6'b11_10_00; // 512:    Orange
        4'hA: get_colour = 6'b01_01_11; // 1024:   Light / Soft Blue
        4'hB: get_colour = 6'b11_01_11; // 2048:   Bright Magenta / Pink
        default: get_colour = center ? 6'hFF : 6'b01_01_01;
      endcase
    end
    return get_colour;
  endfunction


  reg [3:0] grid [0:3][0:3];


  reg [2:0] i, j;
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      R <= 2'b00;
      G <= 2'b00;
      B <= 2'b00;
    end else begin
        {R,G,B} <= 6'b00_00_01;
        if(video_active) {R, G, B} <= 6'b01_00_00;
        if(inside_board) begin
              {R, G, B} <= get_colour(row,col);
        end
    end
  end


  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      for(i = 0; i <= 3; i = i+1) begin
        for(j = 0; j <= 3; j = j+1) begin
		// temporarily setting random values to each cell to visualize colours of each number
          grid[i[1:0]][j[1:0]] <= {i[0],j[0],i[1],j[1]};
        end
      end
    end else begin
      // game logic


    end
  end


endmodule
