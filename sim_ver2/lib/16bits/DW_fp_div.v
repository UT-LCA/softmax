
////////////////////////////////////////////////////////////////////////////////
//
//       This confidential and proprietary software may be used only
//     as authorized by a licensing agreement from Synopsys Inc.
//     In the event of publication, the following notice is applicable:
//
//                    (C) COPYRIGHT 2006 - 2018 SYNOPSYS INC.
//                           ALL RIGHTS RESERVED
//
//       The entire notice above must be reproduced on all authorized
//     copies.
//
// AUTHOR:    Kyung-Nam Han, Mar. 22, 2006
//
// VERSION:   Verilog Simulation Model for DW_fp_div
//
// DesignWare_version: f6e5eef2
// DesignWare_release: O-2018.06-DWBB_201806.5
//
////////////////////////////////////////////////////////////////////////////////

//-------------------------------------------------------------------------------
//
// ABSTRACT: Floating-Point Divider
//
//              DW_fp_div calculates the floating-point division
//              while supporting six rounding modes, including four IEEE
//              standard rounding modes.
//
//              parameters      valid values (defined in the DW manual)
//              ==========      ============
//              sig_width       significand size,  2 to 253 bits
//              exp_width       exponent size,     3 to 31 bits
//              ieee_compliance support the IEEE Compliance 
//                              0 - IEEE 754 compatible without denormal support
//                                  (NaN becomes Infinity, Denormal becomes Zero)
//                              1 - IEEE 754 compatible with denormal support
//                                  (NaN and denormal numbers are supported)
//              faithful_round  select the faithful_rounding that admits 1 ulp error
//                              0 - default value. it keeps all rounding modes
//                              1 - z has 1 ulp error. RND input does not affect
//                                  the output
//
//              Input ports     Size & Description
//              ===========     ==================
//              a               (sig_width + exp_width + 1)-bits
//                              Floating-point Number Input
//              b               (sig_width + exp_width + 1)-bits
//                              Floating-point Number Input
//              rnd             3 bits
//                              Rounding Mode Input
//
//              Output ports    Size & Description
//              ============    ==================
//              z               (sig_width + exp_width + 1)-bits
//                              Floating-point Number Output
//              status          8 bits
//                              Status Flags Output
//

// MODIFIED: 
//   5/7/2007 (0703-SP2):
//     Fixed the rounding error of denormal numbers when ieee_compliance = 1
//   10/18/2007 (0712):
//     Fixed the 'divide by zero' flag when 0/0 
//   1/2/2008 (0712-SP1):
//     New parameter, faithful_round, is introduced
//   6/4/2010 (2010.03-SP3):
//     Removed VCS error [IRIPS] when sig_width = 2 and 3.
//   3/31/2017 (2016.12-SP3): STAR 9001167381
//     Fix of output z between zero and minnorm issue
//   6/15/2017 (2016.12-SP5): Fix of STAR 9001189734 and 9001210054
//   5/01/2018 (2018.06): Modification for the full parameter coverage
//                        at each implementation.
//-----------------------------------------------------------------------------

module DW_fp_div (a, b, rnd, z, status);

  parameter integer sig_width = 10;      // range 2 to 253
  parameter integer exp_width = 5;       // range 3 to 31
  parameter integer ieee_compliance = 0; // range 0 to 1
  parameter integer faithful_round = 0;  // range 0 to 1

  input  [sig_width + exp_width:0] a;
  input  [sig_width + exp_width:0] b;
  input  [2:0] rnd;
  output [sig_width + exp_width:0] z;
  output [7:0] status;

  // synopsys translate_off






  localparam OIIlOlO1 = (faithful_round == 1) && (sig_width >= 11) && (sig_width <= 57);

  //-------------------------------------------------------------------------
  // parameter legality check
  //-------------------------------------------------------------------------
    
 
  initial begin : parameter_check
    integer param_err_flg;

    param_err_flg = 0;
    
      
    if ( (sig_width < 2) || (sig_width > 253) ) begin
      param_err_flg = 1;
      $display(
	"ERROR: %m :\n  Invalid value (%d) for parameter sig_width (legal range: 2 to 253)",
	sig_width );
    end
      
    if ( (exp_width < 3) || (exp_width > 31) ) begin
      param_err_flg = 1;
      $display(
	"ERROR: %m :\n  Invalid value (%d) for parameter exp_width (legal range: 3 to 31)",
	exp_width );
    end
      
    if ( (ieee_compliance < 0) || (ieee_compliance > 1) ) begin
      param_err_flg = 1;
      $display(
	"ERROR: %m :\n  Invalid value (%d) for parameter ieee_compliance (legal range: 0 to 1)",
	ieee_compliance );
    end
      
    if ( (faithful_round < 0) || (faithful_round > 1) ) begin
      param_err_flg = 1;
      $display(
	"ERROR: %m :\n  Invalid value (%d) for parameter faithful_round (legal range: 0 to 1)",
	faithful_round );
    end
    
    if ( param_err_flg == 1) begin
      $display(
        "%m :\n  Simulation aborted due to invalid parameter value(s)");
      $finish;
    end

  end // parameter_check 

  //-------------------------------------------------------------------------


  function [4-1:0] lOOOII1l;
  
    input [2:0] rnd;
    input [0:0] lO011100;
    input [0:0] I0O0O0OO,O011IOO0,I101O11O;

    begin
      lOOOII1l[0] = 0;
      lOOOII1l[1] = O011IOO0|I101O11O;
      lOOOII1l[2] = 0;
      lOOOII1l[3] = 0;
      
      if ($time > 0)
      begin
        case (rnd)
          3'b000:
          begin
            // round to nearest (even)
            lOOOII1l[0] = O011IOO0&(I0O0O0OO|I101O11O);
            lOOOII1l[2] = 1;
            lOOOII1l[3] = 0;
          end
          3'b001:
          begin
            // round to zero
            lOOOII1l[0] = 0;
            lOOOII1l[2] = 0;
            lOOOII1l[3] = 0;
          end
          3'b010:
          begin
            // round to positive infinity
            lOOOII1l[0] = ~lO011100 & (O011IOO0|I101O11O);
            lOOOII1l[2] = ~lO011100;
            lOOOII1l[3] = ~lO011100;
          end
          3'b011:
          begin
            // round to negative infinity
            lOOOII1l[0] = lO011100 & (O011IOO0|I101O11O);
            lOOOII1l[2] = lO011100;
            lOOOII1l[3] = lO011100;
          end
          3'b100:
          begin
            // round to nearest (up)
            lOOOII1l[0] = O011IOO0;
            lOOOII1l[2] = 1;
            lOOOII1l[3] = 0;
          end
          3'b101:
          begin
            // round away form 0
            lOOOII1l[0] = O011IOO0|I101O11O;
            lOOOII1l[2] = 1;
            lOOOII1l[3] = 1;
          end
          default:
          begin
            $display("error! illegal rounding mode.\n");
            $display("a : %b", a);
            $display("rnd : %b", rnd);
          end
        endcase
      end
    end
  endfunction

  reg [(exp_width + sig_width):0] l1l1O100;
  reg [exp_width-1:0] lO101111,lI00O00I;
  reg signed [((exp_width <= 29) ? (((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>65536)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>16777216)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>268435456)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>536870912)?30:29):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>67108864)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>134217728)?28:27):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>33554432)?26:25))):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>1048576)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>4194304)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>8388608)?24:23):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>2097152)?22:21)):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>262144)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>524288)?20:19):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>131072)?18:17)))):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>256)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>4096)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>16384)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>32768)?16:15):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>8192)?14:13)):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>1024)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>2048)?12:11):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>512)?10:9))):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>16)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>64)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>128)?8:7):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>32)?6:5)):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>4)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>8)?4:3):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>2)?2:1))))) + 1 : exp_width + ((sig_width>65536)?((sig_width>16777216)?((sig_width>268435456)?((sig_width>536870912)?30:29):((sig_width>67108864)?((sig_width>134217728)?28:27):((sig_width>33554432)?26:25))):((sig_width>1048576)?((sig_width>4194304)?((sig_width>8388608)?24:23):((sig_width>2097152)?22:21)):((sig_width>262144)?((sig_width>524288)?20:19):((sig_width>131072)?18:17)))):((sig_width>256)?((sig_width>4096)?((sig_width>16384)?((sig_width>32768)?16:15):((sig_width>8192)?14:13)):((sig_width>1024)?((sig_width>2048)?12:11):((sig_width>512)?10:9))):((sig_width>16)?((sig_width>64)?((sig_width>128)?8:7):((sig_width>32)?6:5)):((sig_width>4)?((sig_width>8)?4:3):((sig_width>2)?2:1))))) + 2) - 1:0] IOO1O01O;
  reg signed [((exp_width <= 29) ? (((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>65536)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>16777216)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>268435456)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>536870912)?30:29):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>67108864)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>134217728)?28:27):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>33554432)?26:25))):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>1048576)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>4194304)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>8388608)?24:23):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>2097152)?22:21)):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>262144)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>524288)?20:19):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>131072)?18:17)))):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>256)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>4096)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>16384)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>32768)?16:15):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>8192)?14:13)):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>1024)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>2048)?12:11):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>512)?10:9))):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>16)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>64)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>128)?8:7):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>32)?6:5)):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>4)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>8)?4:3):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>2)?2:1))))) + 1 : exp_width + ((sig_width>65536)?((sig_width>16777216)?((sig_width>268435456)?((sig_width>536870912)?30:29):((sig_width>67108864)?((sig_width>134217728)?28:27):((sig_width>33554432)?26:25))):((sig_width>1048576)?((sig_width>4194304)?((sig_width>8388608)?24:23):((sig_width>2097152)?22:21)):((sig_width>262144)?((sig_width>524288)?20:19):((sig_width>131072)?18:17)))):((sig_width>256)?((sig_width>4096)?((sig_width>16384)?((sig_width>32768)?16:15):((sig_width>8192)?14:13)):((sig_width>1024)?((sig_width>2048)?12:11):((sig_width>512)?10:9))):((sig_width>16)?((sig_width>64)?((sig_width>128)?8:7):((sig_width>32)?6:5)):((sig_width>4)?((sig_width>8)?4:3):((sig_width>2)?2:1))))) + 2) - 1:0] O10101O1;
  reg I1O1O11O;
  reg lO1O0OI1;
  reg [exp_width+1:0] IO10IOO1;
  reg signed [((exp_width <= 29) ? (((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>65536)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>16777216)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>268435456)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>536870912)?30:29):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>67108864)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>134217728)?28:27):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>33554432)?26:25))):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>1048576)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>4194304)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>8388608)?24:23):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>2097152)?22:21)):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>262144)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>524288)?20:19):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>131072)?18:17)))):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>256)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>4096)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>16384)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>32768)?16:15):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>8192)?14:13)):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>1024)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>2048)?12:11):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>512)?10:9))):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>16)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>64)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>128)?8:7):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>32)?6:5)):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>4)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>8)?4:3):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>2)?2:1))))) + 1 : exp_width + ((sig_width>65536)?((sig_width>16777216)?((sig_width>268435456)?((sig_width>536870912)?30:29):((sig_width>67108864)?((sig_width>134217728)?28:27):((sig_width>33554432)?26:25))):((sig_width>1048576)?((sig_width>4194304)?((sig_width>8388608)?24:23):((sig_width>2097152)?22:21)):((sig_width>262144)?((sig_width>524288)?20:19):((sig_width>131072)?18:17)))):((sig_width>256)?((sig_width>4096)?((sig_width>16384)?((sig_width>32768)?16:15):((sig_width>8192)?14:13)):((sig_width>1024)?((sig_width>2048)?12:11):((sig_width>512)?10:9))):((sig_width>16)?((sig_width>64)?((sig_width>128)?8:7):((sig_width>32)?6:5)):((sig_width>4)?((sig_width>8)?4:3):((sig_width>2)?2:1))))) + 2) - 1:0] l10OO10O;
  reg OlOO00lO;
  reg [sig_width:0] OOIl0010,IOOl0lII,l11Illl0,lO001Ol0,I0OI1lO0;
  reg [sig_width:0] IOIlII10;
  reg [(2 * sig_width + 2)  :0] O10110O1;
  reg [sig_width:0] O011IOO0;
  reg I101O11O,lO011100;
  reg [1:0] I11IO1I1;
  reg [4-1:0] OO000O0O;
  reg [8    -1:0] O00OO1I0;
  reg [(exp_width + sig_width):0] IIl1O10O;
  reg [(exp_width + sig_width):0] I00lIO1l;
  reg lOI111I1;
  reg O100O11l;
  reg l10OO1I0;
  reg l1O1Ol0O;
  reg I000lO00;
  reg l1OllI0I;
  reg lO00I10I;
  reg IIIl11O1;
  reg OOO111OO;
  reg l000I1O0;
  reg [sig_width - 1:0] O00O1Ol1;
  reg [sig_width - 1:0] II01O1O0;
  reg [7:0] OIIO0OOl;
  reg [7:0] l0III011;
  reg signed [((exp_width <= 29) ? (((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>65536)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>16777216)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>268435456)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>536870912)?30:29):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>67108864)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>134217728)?28:27):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>33554432)?26:25))):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>1048576)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>4194304)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>8388608)?24:23):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>2097152)?22:21)):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>262144)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>524288)?20:19):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>131072)?18:17)))):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>256)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>4096)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>16384)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>32768)?16:15):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>8192)?14:13)):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>1024)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>2048)?12:11):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>512)?10:9))):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>16)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>64)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>128)?8:7):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>32)?6:5)):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>4)?(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>8)?4:3):(((1 << exp_width) + sig_width + ((1 << (exp_width-1)) - 1) - 1>2)?2:1))))) + 1 : exp_width + ((sig_width>65536)?((sig_width>16777216)?((sig_width>268435456)?((sig_width>536870912)?30:29):((sig_width>67108864)?((sig_width>134217728)?28:27):((sig_width>33554432)?26:25))):((sig_width>1048576)?((sig_width>4194304)?((sig_width>8388608)?24:23):((sig_width>2097152)?22:21)):((sig_width>262144)?((sig_width>524288)?20:19):((sig_width>131072)?18:17)))):((sig_width>256)?((sig_width>4096)?((sig_width>16384)?((sig_width>32768)?16:15):((sig_width>8192)?14:13)):((sig_width>1024)?((sig_width>2048)?12:11):((sig_width>512)?10:9))):((sig_width>16)?((sig_width>64)?((sig_width>128)?8:7):((sig_width>32)?6:5)):((sig_width>4)?((sig_width>8)?4:3):((sig_width>2)?2:1))))) + 2) - 1:0] OO0lIO1O;
  reg [sig_width:0] II0IIO1O;
  reg [sig_width:0] O1lO00O0;
  reg [sig_width:0] I0I0Il0O;
  reg [8:0] l110l11I;
  reg [8:0] IO00O1O1;
  reg [9:0] IOOlIOOO;
  reg [sig_width + 9:0] OOI10OIO;
  reg l0IO1lOO;
  reg [8:0] OO0OO1I0;
  reg [sig_width + 9:0] O00OI010;
  reg [sig_width + 1:0] IOIlOO00;
  reg [(2 * (sig_width - 3)) - 1:0] O0O0IIII;
  reg [sig_width + 3:0] II11llO0;
  reg [sig_width + 3:0] l0101100;
  reg [sig_width + 3:0] l0I1OOll;
  reg OIlI10I1;
  reg [sig_width + 3:0] Ol1O10O0;
  reg [((sig_width >= 11) ? 2 * sig_width - 21 : 0):0] O1l11OIO;
  reg [((sig_width >= 11) ? sig_width - 11 : 0):0] Il101Il1;
  reg [((sig_width >= 11) ? 2 * sig_width - 21 : 0):0] IOll10OO;
  reg [sig_width + 3:0] O0l0O011;
  reg OOO01OO1;
  reg [sig_width + 3:0] O0O1011O;
  reg [((sig_width >= 25) ? sig_width - 25 : 0):0] llOO0II1;
  reg [((sig_width >= 24) ? 2 * sig_width - 47 : 0):0] O010I0IO;
  reg [((sig_width >= 24) ? 2 * sig_width - 47 : 0):0] OOOl110I;
  reg [((sig_width >= 25) ? sig_width - 25 : 0):0] O00O00O1;
  reg [sig_width + 3:0] lI100I0I;
  reg I10l01Il;
  reg [sig_width + 3:0] O1O0011O;
  reg [8:0] O1O1O01l;
  reg [sig_width + 3:0] l0I1OI0l;
  reg [sig_width + 3:0] IIOI0lOO;
  reg [sig_width + 3:0] O11OOOOl;
  reg [8:8 - sig_width] OO1110O0;
  reg [sig_width:0] I01II0I0;
  reg [sig_width:0] IOIOI010;
  reg [sig_width:0] IOO101lO;
  reg [sig_width:0] OlIlOOIO;
  reg I010IlI0;
  reg I11OIl0O;
  reg Ol01O010;
  reg Ol011lO0;
  reg I11OOI1O;
  reg [((sig_width >= 25) ? sig_width - 23 + 0 : 0) - 1:0] I110OIOO;
  reg [(2 * ((sig_width >= 25) ? sig_width - 23 + 0 : 0)) - 1:0] O0OOIl0l;
  reg [((((sig_width >= 25) ? 2 * sig_width - 47 : 0) + 2 * 0) - (((sig_width >= 25) ? sig_width - 23 : 0) + 2 * 0 - 0) + 1) - 1:0] lI0I111I;
  reg [(((sig_width >= 25) ? sig_width + 3 : 0) - (((sig_width >= 25) ? 27 : 0) - 0) + 1) - 1:0] O10I0O00;
  reg [(((((sig_width >= 25) ? 2 * sig_width - 47 : 0) + 2 * 0) - (((sig_width >= 25) ? sig_width - 23 : 0) + 2 * 0 - 0) + 1) + (((sig_width >= 25) ? sig_width + 3 : 0) - (((sig_width >= 25) ? 27 : 0) - 0) + 1)) - 1:0] O100101I;
  reg [(sig_width - 24) - 1:0] O0OI1IO1;
  reg [(((sig_width >= 11) ? sig_width + 1 : 0) - (((sig_width >= 11) ? 12 : 0) - 0) + 1) - 1:0] lI1I01Ol;
  reg [(2 * (((sig_width >= 11) ? sig_width + 1 : 0) - (((sig_width >= 11) ? 12 : 0) - 0) + 1)) - 1:0] I0l1O011;
  reg [((((sig_width >= 11) ? 2 * sig_width - 21 : 0) + 2 * 0) - (((sig_width >= 11) ? sig_width - 10 : 0) + 2 * 0) + 1 + 0) - 1:0] l0OOOIll;
  reg [(((sig_width >= 11) ? sig_width + 3 : 0) - ((sig_width >= 11) ? 14 : 0) + 1) - 1:0] lO0110ll;
  reg [((((sig_width >= 11) ? sig_width + 3 : 0) - ((sig_width >= 11) ? 14 : 0) + 1) + ((((sig_width >= 11) ? 2 * sig_width - 21 : 0) + 2 * 0) - (((sig_width >= 11) ? sig_width - 10 : 0) + 2 * 0) + 1 + 0)) - 1:0] IO0I1O10;
  reg [(2 * ((sig_width - 3) + 2)) - 1:0] O101OOOO;
  reg [(sig_width + 4 + 2) - 1:0] O010OOO1;
  reg [(sig_width + 4 + 2) - 1:0] O1I10I10;
  reg [(sig_width + 4 + 2) - 1:0] l101O0Ol;



  always @(a or b or rnd) begin : DW_O1OO11I0
    lO011100 = a[(exp_width + sig_width)] ^ b[(exp_width + sig_width)];
    lO101111 = a[((exp_width + sig_width) - 1):sig_width];
    lI00O00I = b[((exp_width + sig_width) - 1):sig_width];
    O00O1Ol1 = a[(sig_width - 1):0];
    II01O1O0 = b[(sig_width - 1):0];
    OIIO0OOl = 0;
    l0III011 = 0;
    IOIlII10 = 0;

    O00OO1I0 = 0;

    // division table for special inputs
    //
    //  -------------------------------------------------
    //         a      /       b      |       result
    //  -------------------------------------------------
    //        nan     |      any     |        nan
    //        any     |      nan     |        nan
    //        inf     |      inf     |        nan
    //         0      |       0      |        nan
    //        inf     |      any     |        inf
    //        any     |       0      |        inf
    //         0      |      any     |         0
    //        any     |      inf     |         0
    //  -------------------------------------------------
    // when ieee_compliance = 0, 
    // denormal numbers are considered as zero and 
    // nans are considered as infinity

    if (ieee_compliance)
    begin
      lOI111I1 = (lO101111 == ((((1 << (exp_width-1)) - 1) * 2) + 1)) & (O00O1Ol1 == 0);
      O100O11l = (lI00O00I == ((((1 << (exp_width-1)) - 1) * 2) + 1)) & (II01O1O0 == 0);
      l10OO1I0 = (lO101111 == ((((1 << (exp_width-1)) - 1) * 2) + 1)) & (O00O1Ol1 != 0);
      l1O1Ol0O = (lI00O00I == ((((1 << (exp_width-1)) - 1) * 2) + 1)) & (II01O1O0 != 0);
      I000lO00 = (lO101111 == 0) & (O00O1Ol1 == 0);
      l1OllI0I = (lI00O00I == 0) & (II01O1O0 == 0);
      lO00I10I = (lO101111 == 0) & (O00O1Ol1 != 0);
      IIIl11O1 = (lI00O00I == 0) & (II01O1O0 != 0);

      IIl1O10O = {lO011100, {(exp_width){1'b1}}, {(sig_width){1'b0}}}; 
      I00lIO1l = {1'b0, {(exp_width){1'b1}}, {(sig_width - 1){1'b0}}, 1'b1};
    end
    else
    begin
      lOI111I1 = (lO101111 == ((((1 << (exp_width-1)) - 1) * 2) + 1));
      O100O11l = (lI00O00I == ((((1 << (exp_width-1)) - 1) * 2) + 1));
      l10OO1I0 = 0;
      l1O1Ol0O = 0;
      I000lO00 = (lO101111 == 0);
      l1OllI0I = (lI00O00I == 0);
      lO00I10I = 0;
      IIIl11O1 = 0;

      IIl1O10O = {lO011100, {(exp_width){1'b1}}, {(sig_width){1'b0}}};
      I00lIO1l = {1'b0, {(exp_width){1'b1}}, {(sig_width){1'b0}}};
    end

    O00OO1I0[7] = (ieee_compliance) ?
            l1OllI0I & ~(I000lO00 | l10OO1I0 | lOI111I1) :
            l1OllI0I & ~(I000lO00 | l10OO1I0); 

    if (l10OO1I0 || l1O1Ol0O || (lOI111I1 && O100O11l) || (I000lO00 && l1OllI0I)) begin : DW_lO0IO11l
      l1l1O100 = I00lIO1l;
      O00OO1I0[2] = 1;
    end
    else if (lOI111I1 || l1OllI0I) begin : DW_OOOOlOI0
      l1l1O100 = IIl1O10O;
      O00OO1I0[1] = 1;
    end
    else if (I000lO00 || O100O11l) begin : DW_I011I100
      O00OO1I0[0] = 1;
      l1l1O100 = 0;
      l1l1O100[(exp_width + sig_width)] = lO011100;
    end
  
    else begin : DW_ll0I1O1O
      if (ieee_compliance) begin
        if (lO00I10I) begin
          OOIl0010 = {1'b0, a[(sig_width - 1):0]};

          while(OOIl0010[sig_width] != 1) begin
            OOIl0010 = OOIl0010 << 1;
            OIIO0OOl = OIIO0OOl + 1;
          end
        end 
        else begin
          OOIl0010 = {1'b1, a[(sig_width - 1):0]};
        end

        if (IIIl11O1) begin
          IOOl0lII = {1'b0, b[(sig_width - 1):0]};
          while(IOOl0lII[sig_width] != 1) begin
            IOOl0lII = IOOl0lII << 1;
            l0III011 = l0III011 + 1;
          end
        end 
        else begin
          IOOl0lII = {1'b1, b[(sig_width - 1):0]};
        end
      end
      else begin
        OOIl0010 = {1'b1, a[(sig_width - 1):0]};
        IOOl0lII = {1'b1, b[(sig_width - 1):0]};
      end

      Ol01O010 = (OOIl0010 == IOOl0lII);
      I11OOI1O = (IOOl0lII[sig_width - 1:0] == 0);
      II0IIO1O = OOIl0010;
      O1lO00O0 = (ieee_compliance) ? IOOl0lII : {1'b1, II01O1O0};
      I0I0Il0O = (OIIlOlO1) ? O1lO00O0 : {O1lO00O0, 1'b0};
      l110l11I = (sig_width >= 9) ? I0I0Il0O[sig_width - 1:((sig_width >= 9) ? sig_width - 9 : 0)] : {I0I0Il0O[sig_width - 1:0], {(((sig_width >= 9) ? 1 : 9 - sig_width)){1'b0}}};
      IOOlIOOO = {1'b1, l110l11I[8:0]};
      IO00O1O1 = {1'b1, 18'b0} / (IOOlIOOO + 1);
      OOI10OIO = IO00O1O1 * II0IIO1O;
      l0IO1lOO = OOI10OIO[sig_width + 9];
      OO0OO1I0 = (l0IO1lOO) ? OOI10OIO[sig_width + 9:sig_width + 1] : OOI10OIO[sig_width + 8:sig_width];
      O00OI010 = I0I0Il0O * IO00O1O1;
      IOIlOO00 = ~O00OI010[sig_width + 1:0];

      O101OOOO = OOI10OIO[(sig_width + 10) - 1:(sig_width + 10) - (sig_width - 3) - 2] *
                IOIlOO00[(sig_width + 2) - 1:(sig_width + 2) - (sig_width - 3) - 2];
      O010OOO1 = {7'b0, O101OOOO[(2 * ((sig_width - 3) + 2)) - 1:(2 * ((sig_width - 3) + 2)) - (sig_width + 4 + 2) + 7]};
      O1I10I10 = OOI10OIO[(sig_width + 10) - 1:(sig_width + 10) - (sig_width + 4 + 2)];
      l101O0Ol = O1I10I10 + O010OOO1;

      O0O0IIII = (sig_width <= 8) ? 0 :
               OOI10OIO[sig_width + 9:((sig_width <= 8) ? 0 : sig_width + 9 - (sig_width - 3) + 1)] * 
               IOIlOO00[sig_width + 1:((sig_width <= 8) ? 0 : sig_width + 1 - (sig_width - 3) + 1)];
      l0101100 = (sig_width <= 8) ? 0 :
               {6'b0, O0O0IIII[((sig_width == 3) ? 0 : (2 * (sig_width - 3)) - 1):(2 * (sig_width - 3)) - 1 - sig_width + 5 - 1]};
      II11llO0 = OOI10OIO[sig_width + 9:6];
      l0I1OOll = II11llO0 + l0101100;
      OIlI10I1 = l0I1OOll[sig_width + 3];
      Ol1O10O0 = ((sig_width >= 14)) ?
             l101O0Ol[(sig_width + 4 + 2) - 1:(sig_width + 4 + 2) - (sig_width + 4)] :
             ((OIlI10I1) ? l0I1OOll : {l0I1OOll[sig_width + 2:0], 1'b0});

      lI1I01Ol = IOIlOO00[((sig_width >= 11) ? sig_width + 1 : 0):(((sig_width >= 11) ? 12 : 0) - 0)];
      O1l11OIO = (sig_width >= 11) ? IOIlOO00[((sig_width >= 11) ? sig_width + 1 : 0):((sig_width >= 11) ? 12 : 0)] * IOIlOO00[((sig_width >= 11) ? sig_width + 1 : 0):((sig_width >= 11) ? 12 : 0)] : 0;
      Il101Il1 = (sig_width >= 11) ? O1l11OIO[((sig_width >= 11) ? 2 * sig_width - 21 : 0):((sig_width >= 11) ? sig_width - 10 : 0)] : 0;
      IOll10OO = (sig_width >= 11) ? Ol1O10O0[((sig_width >= 11) ? sig_width + 3 : 0):((sig_width >= 11) ? 14 : 0)] * Il101Il1 : 0;

      O0l0O011 = Ol1O10O0 + IOll10OO[((sig_width >= 11) ? 2 * sig_width - 21 : 0):((sig_width >= 11) ? sig_width - 10 : 0)];
      OOO01OO1 = O0l0O011[sig_width + 3];
      O0O1011O = (sig_width <= 28) ? 
             ((OOO01OO1) ? O0l0O011 : {O0l0O011[sig_width + 2:0], 1'b0}) :
             O0l0O011;

      I110OIOO = l0OOOIll[((sig_width == 53)? ((((sig_width >= 11) ? 2 * sig_width - 21 : 0) + 2 * 0) - (((sig_width >= 11) ? sig_width - 10 : 0) + 2 * 0) + 1 + 0) - 1:0):((sig_width == 53)? ((((sig_width >= 11) ? 2 * sig_width - 21 : 0) + 2 * 0) - (((sig_width >= 11) ? sig_width - 10 : 0) + 2 * 0) + 1 + 0) - ((sig_width >= 25) ? sig_width - 23 + 0 : 0):0)];

      O0OOIl0l = I110OIOO * I110OIOO; 
      lI0I111I = O0OOIl0l[(((sig_width >= 25) ? 2 * sig_width - 47 : 0) + 2 * 0):(((sig_width >= 25) ? sig_width - 23 : 0) + 2 * 0 - 0)];
      O10I0O00 = O0O1011O[((sig_width >= 25) ? sig_width + 3 : 0):(((sig_width >= 25) ? 27 : 0) - 0)];
      O100101I = O10I0O00 * lI0I111I;
      O0OI1IO1 = O100101I[((sig_width == 53) ? (((((sig_width >= 25) ? 2 * sig_width - 47 : 0) + 2 * 0) - (((sig_width >= 25) ? sig_width - 23 : 0) + 2 * 0 - 0) + 1) + (((sig_width >= 25) ? sig_width + 3 : 0) - (((sig_width >= 25) ? 27 : 0) - 0) + 1)) - 1:0):((sig_width == 53) ? ((sig_width == 53) ? (((((sig_width >= 25) ? 2 * sig_width - 47 : 0) + 2 * 0) - (((sig_width >= 25) ? sig_width - 23 : 0) + 2 * 0 - 0) + 1) + (((sig_width >= 25) ? sig_width + 3 : 0) - (((sig_width >= 25) ? 27 : 0) - 0) + 1)) - 1:0) - (sig_width - 24) + 1:0)];

      llOO0II1 = (sig_width >= 25) ? Il101Il1[((sig_width >= 25) ? sig_width - 11 : 0):((sig_width >= 25) ? 13 : 0)] : 0;
      O010I0IO = llOO0II1 * llOO0II1;
      OOOl110I = (sig_width >= 25) ? O0O1011O[((sig_width >= 25) ? sig_width + 3 : 0):((sig_width >= 25) ? 27 : 0)] * O010I0IO[((sig_width >= 25) ? 2 * sig_width - 47 : 0):((sig_width >= 25) ? sig_width - 23 : 0)] : 0;
      O00O00O1 = (sig_width >= 25) ? OOOl110I[((sig_width >= 25) ? 2 * sig_width - 47 : 0):((sig_width >= 25) ? sig_width - 22 : 0)] : 0;
      lI100I0I = (sig_width >= 25) ? O0O1011O + O00O00O1 : O0O1011O;

      I10l01Il = lI100I0I[sig_width + 3];
      O1O0011O = ((I10l01Il) ? lI100I0I : {lI100I0I[sig_width + 2:0], 1'b0});

      O1O1O01l = (sig_width == 8) ? OO0OO1I0 + 1 : 
               (sig_width < 8)  ? OO0OO1I0 + {1'b1, {(((sig_width > 8) ? 0 : 8 - sig_width - 1) + 1){1'b0}}} : 
                                                 0;
      l0I1OI0l = Ol1O10O0 + 4'b1000;
      IIOI0lOO = O0O1011O + 4'b1000;
      O11OOOOl = O1O0011O + 4'b1000;

      OO1110O0 = (sig_width == 8) ? OO0OO1I0[8:((sig_width > 8) ? 0 : 8 - sig_width - 1) + 1] : 
                   (OO0OO1I0[((sig_width > 8) ? 0 : 8 - sig_width - 1)]) ? O1O1O01l[8:((sig_width > 8) ? 0 : 8 - sig_width - 1) + 1] : 
                                       OO0OO1I0[8:((sig_width > 8) ? 0 : 8 - sig_width - 1) + 1];
      I01II0I0 = (Ol1O10O0[2]) ? l0I1OI0l[sig_width + 3:3] : Ol1O10O0[sig_width + 3:3];
      IOIOI010 = (O0O1011O[2]) ? IIOI0lOO[sig_width + 3:3] : O0O1011O[sig_width + 3:3];
      IOO101lO = (O1O0011O[2]) ? O11OOOOl[sig_width + 3:3] : O1O0011O[sig_width + 3:3];

      OlIlOOIO = (sig_width <= 8) ? OO1110O0 : 
            (sig_width <= 13) ? I01II0I0 : 
            (sig_width <= 28) ? IOIOI010 : 
                                            IOO101lO;

      Ol011lO0 = (OIIlOlO1) ? (OlIlOOIO == 0) : 0;
      I010IlI0 = (sig_width <= 8) ? l0IO1lOO: (sig_width <= 14) ? OIlI10I1 : (sig_width <= 30) ? OOO01OO1 : I10l01Il;
      I11OIl0O = ~Ol01O010 & (II01O1O0 != 0);

      O10110O1 = {OOIl0010,{(sig_width + 2){1'b0}}} / IOOl0lII;
      O011IOO0 = (OIIlOlO1) ? I11OIl0O : {OOIl0010,{(sig_width + 2){1'b0}}} % IOOl0lII;

      // Sep 25 IOO1O01O = ($signed({1'b0, lO101111}) - $signed({1'b0, OIIO0OOl}) + $signed({1'b0, lO00I10I})) - ($signed({1'b0, lI00O00I}) - $signed({1'b0, l0III011}) + $signed({1'b0, IIIl11O1})) + $signed({1'b0, ((1 << (exp_width-1)) - 1)});
      IOO1O01O = ($signed({1'b0, lO101111}) - $signed({1'b0, OIIO0OOl}) + $signed({1'b0, lO00I10I})) - ($signed({1'b0, lI00O00I}) - $signed({1'b0, l0III011}) + $signed({1'b0, IIIl11O1})) + $signed({1'b0, 4'b1111});
      O10101O1 = IOO1O01O - $signed(2'b01);

      lO001Ol0 = (OIIlOlO1) ?
                   ((I11OOI1O & ~ieee_compliance) ? II0IIO1O : OlIlOOIO) :
                   ((~O10110O1[(sig_width + 2)]) ? O10110O1[(sig_width + 2) - 1:1] : O10110O1[(sig_width + 2):2]);
      I11IO1I1 = ~O10110O1[(sig_width + 2)] ? O10110O1[1:0] : O10110O1[2:1];
      l10OO10O = ~O10110O1[(sig_width + 2)] ? O10101O1 : IOO1O01O;
      OOO111OO = ((l10OO10O <= 0) | (l10OO10O[exp_width + 1] < 0));
      I101O11O = (OIIlOlO1) ? 
              ((I11OOI1O | Ol01O010) & ~OOO111OO ? 0 : 1) :
              ((O011IOO0===0)?1'b0:1'b1); 
      Ol01O010 = (OIIlOlO1) ? (OOIl0010 == IOOl0lII) : 0;

      if (ieee_compliance) begin
        if ((l10OO10O <= 0) | (l10OO10O < 0)) begin

          OO0lIO1O = 1 - l10OO10O + Ol01O010;
        
          {lO001Ol0, IOIlII10} = {lO001Ol0, {(sig_width + 1){1'b0}}} >> OO0lIO1O;

          if (OO0lIO1O > sig_width + 1) begin
            I101O11O = 1;
          end

          I11IO1I1[1] = lO001Ol0[0];
          I11IO1I1[0] = IOIlII10[sig_width];

          if (IOIlII10[sig_width - 1:0] != 0) begin
            I101O11O = 1;
          end
        end
      end

      OO000O0O = lOOOII1l(rnd, lO011100, I11IO1I1[1], I11IO1I1[0], I101O11O);
   
      I0OI1lO0 = (OIIlOlO1) ? lO001Ol0 :
                    (OO000O0O[0] === 1)? (lO001Ol0+1):lO001Ol0;
      l000I1O0 = (OIIlOlO1) ? (OOIl0010 < IOOl0lII) : 0;

      if ((l10OO10O >= ((((1 << (exp_width-1)) - 1) * 2) + 1)) & (l10OO10O >= 0)) begin
        O00OO1I0[4] = 1;
        O00OO1I0[5] = 1;
        if(OO000O0O[2] === 1) begin
          l11Illl0 = IIl1O10O[sig_width:0];
          IO10IOO1 = ((((1 << (exp_width-1)) - 1) * 2) + 1);
          O00OO1I0[1] = 1;
        end
        else begin
          l11Illl0 = -1;
          IO10IOO1 = ((((1 << (exp_width-1)) - 1) * 2) + 1) - 1;
        end
      end
  
      else if (l10OO10O <= 0) begin
        O00OO1I0[3] = 1'b1;

        if (ieee_compliance == 0) begin
          O00OO1I0[5] = 1;

          if ((l000I1O0 == 0) && ((l10OO10O == 0) && (lO001Ol0 == {(sig_width + 1){1'b1}})) && ((rnd == 0) || (rnd == 5) || ((rnd == 2) && (~lO011100)) || ((rnd == 3) && lO011100))) begin
            l11Illl0 = 0;
            IO10IOO1 = 1;
          end
          else begin
            if (OO000O0O[3] === 1) begin
              l11Illl0 = 0;
              IO10IOO1 = 0 + 1;
            end
            else begin
              l11Illl0 = 0;
              IO10IOO1 = 0;
              O00OO1I0[0] = 1;
            end
          end
        end
        else begin
          l11Illl0 = I0OI1lO0;

          IO10IOO1 = I0OI1lO0[sig_width];
        end
      end
      else begin
        l11Illl0 = (Ol01O010 & OIIlOlO1) ? 0 : I0OI1lO0;
        IO10IOO1 = l10OO10O;
      end

      if ((l11Illl0[sig_width - 1:0] == 0) & (IO10IOO1[exp_width - 1:0] == 0)) begin
        O00OO1I0[0] = 1;
      end
  
      O00OO1I0[5] = O00OO1I0[5] | OO000O0O[1];
   
      l1l1O100 = {lO011100,IO10IOO1[exp_width-1:0],l11Illl0[sig_width-1:0]};
    end
  end
   
  assign status = ((^(a ^ a) !== 1'b0) || (^(b ^ b) !== 1'b0) || (^(rnd ^ rnd) !== 1'b0)) ? {8'bx} : O00OO1I0;
  assign z = ((^(a ^ a) !== 1'b0) || (^(b ^ b) !== 1'b0) || (^(rnd ^ rnd) !== 1'b0)) ? {8'bx} : l1l1O100;

  // synopsys translate_on

endmodule
/* vcs gen_ip dbg_ip off */
 /* */
  
  
  
