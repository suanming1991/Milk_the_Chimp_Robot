module reset_synch(clk,RST_n,rst_n);

input clk, RST_n;
output rst_n;
reg rst_n;
reg q;

always @(negedge RST_n or negedge clk)
begin
  if(!RST_n) begin
      q  <= 1'b0;
      rst_n <= 1'b0;
end  
   else begin
      q  <= 1'b1;
      rst_n <= q;
end 
end 
endmodule 