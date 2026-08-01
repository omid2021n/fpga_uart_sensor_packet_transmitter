`timescale 1ns/1ps
// -----------------------------------------------------------------------
// uart_tx.sv
// UART transmitter, explicit 4-state FSM: IDLE, SETUP, SEND, STOP.
// 1 start bit, DATA_BITS data bits (LSB first), 1 stop bit.
// -----------------------------------------------------------------------
module uart_tx #(
  parameter int SYS_CLK   = 25_000_000, // Hz
  parameter int BAUD_RATE = 115200,
  parameter int DATA_BITS = 8
)(
  input  logic clk,
  input  logic n_rst,          // active-low async reset
  input  logic en_tx,          // pulse high for 1 clk to start a transmission
  input  logic [DATA_BITS-1:0] data,

  output logic ready,          // high when idle and able to accept new data
  output logic tx
);

  //----------------------------------------------------------
  // Baud tick generator
  //----------------------------------------------------------
  localparam int BAUD_DIV = SYS_CLK / BAUD_RATE;

  logic [$clog2(BAUD_DIV)-1:0] baud_count;
  logic                        baud_tick;

  always_ff @(posedge clk or negedge n_rst) begin
    if (!n_rst) begin
      baud_count <= '0;
      baud_tick  <= 1'b0;
    end else if(!ready) begin
    
        if (baud_count == BAUD_DIV - 1) begin
            baud_count <= '0;
            baud_tick  <= 1'b1;
        end else begin
            baud_count <= baud_count + 1'b1;
            baud_tick  <= 1'b0;
        end
      end else begin
      baud_count <= '0;    // hold at 0 while idle
      baud_tick  <= 1'b0;
    end
  end

  //----------------------------------------------------------
  // TX FSM
  //----------------------------------------------------------
  typedef enum logic [1:0] {IDLE, SETUP, SEND, STOP} state_t;
  state_t state;

  logic [$clog2(DATA_BITS)-1:0] bit_counter;
  logic [DATA_BITS-1:0]         tx_shift;

  always_ff @(posedge clk or negedge n_rst) begin
    if (!n_rst) begin
      state       <= IDLE;
      tx          <= 1'b1;   // idle line is high
      ready       <= 1'b1;
      bit_counter <= '0;
      tx_shift    <= '0;
    end else begin
      case (state)

        IDLE: begin
          tx    <= 1'b1;
          ready <= 1'b1;
          if (en_tx) begin
            tx_shift    <= data;
            ready       <= 1'b0;
            bit_counter <= '0;
            state       <= SETUP;
          end
        end

        SETUP: begin
          if (baud_tick) begin
            tx    <= 1'b0;   // start bit
            state <= SEND;
          end
        end

        SEND: begin
          if (baud_tick) begin
            tx          <= tx_shift[0];
            tx_shift    <= {1'b0, tx_shift[DATA_BITS-1:1]};
            bit_counter <= bit_counter + 1'b1;
            if (bit_counter == DATA_BITS - 1) begin
              state <= STOP;
            end
          end
        end

        STOP: begin
          if (baud_tick) begin
            tx    <= 1'b1;   // stop bit
            ready <= 1'b1;
            state <= IDLE;
          end
        end

        default: state <= IDLE;  // recover from illegal state

      endcase
    end
  end

endmodule
