 #################################################################
# uart_top.sdc
# Timing constraints for uart_top
#################################################################

# Clock: 25 MHz on port clk_25M (period = 1/25,000,000 Hz = 40.000 ns)
create_clock -name clk_25M -period 40.000 [get_ports {clk_25M}]
derive_clock_uncertainty


# rst: asynchronous, active-low reset - excluded from setup/hold timing
set_false_path -from [get_ports {rst}]

# tx: slow (115200 baud) asynchronous serial output, no shared clock
# with any downstream device - pin-level ns timing is irrelevant here
set_false_path -to [get_ports {tx}]
