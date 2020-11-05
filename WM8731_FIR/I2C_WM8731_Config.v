`timescale 1ns/1ns
module	I2C_WM8731_Config
(
	input		[3:0]	LUT_INDEX,
	output	reg	[23:0]	LUT_DATA,
	output		[3:0]	LUT_SIZE
);

assign	LUT_SIZE = 4'd10;

//-----------------------------------------------------------------
/////////////////////	Config Data LUT	  //////////////////////////	
always@(*)
begin
	case(LUT_INDEX)
	/*
	//////////////////////////////////////BYPASS////////////////////////////////////////
 	 0:LUT_DATA <= {8'h34,8'h00,8'h17};//0000_000_0_1001_0111//R0:Left Line In 0 db gain to ADC,ENSABLE MUTE,Enable Simultaneous Load
	 1:LUT_DATA <= {8'h34,8'h02,8'h17};//0000_001_0_1001_0111//R1:Right Line In 0 db gain to ADC,ENSABLE MUTE,Enable Simultaneous Load
	 2:LUT_DATA <= {8'h34,8'h04,8'h79};//0000_010_0_0111_1001//R2:Left Channel Headphone Output Volume Control 0 db
	 3:LUT_DATA <= {8'h34,8'h06,8'h79};//0000_011_0_0111_1001//R3:Right Channel Headphone Output Volume Control 0 db
     4:LUT_DATA <= {8'h34,8'h08,8'h0A};//0000_100_0_0000_1010//R4:BYPASS+LINE_IN_ADC
     5:LUT_DATA <= {8'h34,8'h0A,8'h01};//0000_101_0_0000_0001//R5:Disable High Pass Filter,Disable De-emphasis Control,Disable soft mute,clear offset
     6:LUT_DATA <= {8'h34,8'h0C,8'h00};//0000_101_1_0110_0000//R6:Oscillator Power Down,CLKOUT power down,others power on
     7:LUT_DATA <= {8'h34,8'h0E,8'h53};//0000_111_0_0101_0011//R7:DSP Format,16 Bit Data Lenghth,LRP=1,Enable Master Mode,Don't invert BCLK
     8:LUT_DATA <= {8'h34,8'h10,8'h23};//0001_000_0_0010_0011//R8:USB Mode,ADC and DAC slamping rate is 44.1KHz while MCLK is 12MHz,Core Clock is MCLK,CLOCKOUT is Core Clock
     9:LUT_DATA <= {8'h34,8'h12,8'h01};//0001_001_0_0000_0001//R9:Active Digtal Audio Interface
	 default:   LUT_DATA <= 24'h000000;
	 */
	 //////////////////////////////////////MIC_IN////////////////////////////////////////
	 0:LUT_DATA <= {8'h34,8'h00,8'h17};//0000_000_0_1001_0111//R0:Left Line In 0 db gain to ADC,ENSABLE MUTE,Enable Simultaneous Load
	 1:LUT_DATA <= {8'h34,8'h02,8'h17};//0000_001_0_1001_0111//R1:Right Line In 0 db gain to ADC,ENSABLE MUTE,Enable Simultaneous Load
	 2:LUT_DATA <= {8'h34,8'h04,8'h79};//0000_010_0_0111_1001//R2:Left Channel Headphone Output Volume Control 0 db
	 3:LUT_DATA <= {8'h34,8'h06,8'h79};//0000_011_0_0111_1001//R3:Right Channel Headphone Output Volume Control 0 db
     4:LUT_DATA <= {8'h34,8'h08,8'h0D};//0000_100_0_0000_1101//R4:MIC_IN_ADC + BYPASS
     5:LUT_DATA <= {8'h34,8'h0A,8'h01};//0000_101_0_0000_0001//R5:Disable High Pass Filter,Disable De-emphasis Control,Disable soft mute,clear offset
     6:LUT_DATA <= {8'h34,8'h0C,8'h00};//0000_101_1_0110_0000//R6:Oscillator Power Down,CLKOUT power down,others power on
     7:LUT_DATA <= {8'h34,8'h0E,8'h53};//0000_111_0_0101_0011//R7:DSP Format,16 Bit Data Lenghth,LRP=1,Enable Master Mode,Don't invert BCLK
     8:LUT_DATA <= {8'h34,8'h10,8'h23};//0001_000_0_0010_0011//R8:USB Mode,ADC and DAC slamping rate is 44.1KHz while MCLK is 12MHz,Core Clock is MCLK,CLOCKOUT is Core Clock
     9:LUT_DATA <= {8'h34,8'h12,8'h01};//0001_001_0_0000_0001//R9:Active Digtal Audio Interface
     default:   LUT_DATA <= 24'h000000;
     
	endcase
end
endmodule

