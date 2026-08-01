`timescale 1ns/1ps
// -----------------------------------------------------------------------
// uart_tx_package.sv
// Sends 6 x 12-bit temperature readings to the PC over uart_tx, as
// a 13-byte packet, once every PULSE_DIVIDE clock cycles.
// -----------------------------------------------------------------------
module top_tx_package_8 #(
  parameter int SYS_CLK      = 25_000_000,
  parameter int PULSE_DIVIDE = SYS_CLK / 2   // cycles between sends;
                                              // override for fast sim,
                                              // leave default for real HW
)(
  input  logic clk_25M,
  input  logic rst,     // active-low, matches uart_tx's n_rst
  output logic tx
);

  logic [7:0] data;
  logic       en_tx;
  logic       ready;

  uart_tx #(
    .SYS_CLK (SYS_CLK)
  ) dut (
    .clk   (clk_25M),
    .n_rst (rst),
    .en_tx (en_tx),
    .data  (data),
    .ready (ready),
    .tx    (tx)
  );

  //------------------------------------------------------------
  // Pulse generator: fires 'pulse' once every PULSE_DIVIDE cycles
  //------------------------------------------------------------
  logic [$clog2(PULSE_DIVIDE)-1:0] counter;
  logic pulse;

  always_ff @(posedge clk_25M or negedge rst) begin
    if (!rst) begin
      counter <= '0;
      pulse   <= 1'b0;
    end else if (counter == PULSE_DIVIDE - 1) begin
      counter <= '0;
      pulse   <= 1'b1;
    end else begin
      counter <= counter + 1'b1;
      pulse   <= 1'b0;
    end
  end

  //------------------------------------------------------------
  // Temperature inputs - 12-bit each, MAX6675-style, 6 sensors.
  // TODO: replace these placeholders with your real SPI sensor
  // read logic.
  //------------------------------------------------------------
  logic [11:0] temp1, temp2, temp3, temp4, temp5, temp6;
  assign temp1 = 12'd1;
  assign temp2 = 12'd2;
  assign temp3 = 12'd3;
  assign temp4 = 12'd4;
  assign temp5 = 12'd5;
  assign temp6 = 12'd6;

  //------------------------------------------------------------
  // Packet format (13 bytes):
  //   [0]  0xAA                - sync byte, PC looks for this
  //   [1]  4'h0, temp1[11:8]   - high nibble, sensor 1
  //   [2]  temp1[7:0]          - low byte, sensor 1
  //   [3]  4'h0, temp2[11:8]   - high nibble, sensor 2
  //   [4]  temp2[7:0]          - low byte, sensor 2
  //   [5]  4'h0, temp3[11:8]   - high nibble, sensor 3
  //   [6]  temp3[7:0]          - low byte, sensor 3
  //   [7]  4'h0, temp4[11:8]   - high nibble, sensor 4
  //   [8]  temp4[7:0]          - low byte, sensor 4
  //   [9]  4'h0, temp5[11:8]   - high nibble, sensor 5
  //   [10] temp5[7:0]          - low byte, sensor 5
  //   [11] 4'h0, temp6[11:8]   - high nibble, sensor 6
  //   [12] temp6[7:0]          - low byte, sensor 6
  //------------------------------------------------------------
  localparam int PACKET_BYTES = 13;

  logic [7:0] packet_live [0:PACKET_BYTES-1];
  always_comb begin
    packet_live[0]  = 8'hAA;
    packet_live[1]  = {4'h0, temp1[11:8]};
    packet_live[2]  = temp1[7:0];
    packet_live[3]  = {4'h0, temp1[11:8]};
    packet_live[4]  = temp2[7:0];
    packet_live[5]  = {4'h0, temp1[11:8]};
    packet_live[6]  = temp3[7:0];
    packet_live[7]  = {4'h0, temp1[11:8]};
    packet_live[8]  = temp4[7:0];
    packet_live[9]  = {4'h0, temp1[11:8]};
    packet_live[10] = temp5[7:0];
    packet_live[11] = {4'h0, temp1[11:8]};
    packet_live[12] = temp6[7:0];
  end

  // Snapshot: captures a self-consistent copy of the packet at the
  // moment a send begins, so all 13 bytes belong to the SAME reading
  // even if temp1..temp6 change mid-transmission.
  logic [7:0] packet_snap [0:PACKET_BYTES-1];

  typedef enum logic [1:0] {IDLE, WAIT_START, WAIT_DONE} pkt_state_t;
  pkt_state_t pkt_state;

  logic [$clog2(PACKET_BYTES)-1:0] byte_index;

  always_ff @(posedge clk_25M or negedge rst) begin
    if (!rst) begin
      pkt_state  <= IDLE;
      byte_index <= '0;
      data       <= '0;
      en_tx      <= 1'b0;
    end else begin
      en_tx <= 1'b0;  // default low; pulsed high explicitly below

      case (pkt_state)

        IDLE: begin
          byte_index <= '0;
          if (pulse && ready) begin
            packet_snap <= packet_live;   // capture whole packet at once
            data        <= packet_live[0];
            en_tx       <= 1'b1;
            pkt_state   <= WAIT_START;
          end
        end

        WAIT_START: begin
          if (!ready) begin
            pkt_state <= WAIT_DONE;
          end
        end

        WAIT_DONE: begin
          if (ready) begin
            if (byte_index == PACKET_BYTES - 1) begin
              pkt_state <= IDLE;
            end else begin
              byte_index <= byte_index + 1'b1;
              data       <= packet_snap[byte_index + 1'b1];
              en_tx      <= 1'b1;
              pkt_state  <= WAIT_START;
            end
          end
        end

        default: pkt_state <= IDLE;

      endcase
    end
  end

endmodule
