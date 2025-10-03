library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fir_filter_pkg.all;


entity fir_filter is
    Port (
        CLK    : in  std_logic;
        RST_n  : in  std_logic;  -- Active-low reset
        VIN    : in  std_logic;  -- Validation signal for input
        DIN    : in  std_logic_vector(10 downto 0);  -- 11-bit fixed-point input data
        B0     : in  std_logic_vector(10 downto 0);        
        B1     : in  std_logic_vector(10 downto 0);        
        B2     : in  std_logic_vector(10 downto 0);        
        B3     : in  std_logic_vector(10 downto 0);        
        B4     : in  std_logic_vector(10 downto 0);        
        B5     : in  std_logic_vector(10 downto 0);        
        B6     : in  std_logic_vector(10 downto 0);        
        B7     : in  std_logic_vector(10 downto 0);        
        B8     : in  std_logic_vector(10 downto 0);        
        B9     : in  std_logic_vector(10 downto 0);        
        B10    : in  std_logic_vector(10 downto 0);   
        DOUT   : out std_logic_vector(10 downto 0);  -- 11-bit fixed-point output data
        VOUT   : out std_logic  -- Validation signal for output
    );
end fir_filter;

architecture Behavioral of fir_filter is
    component reg_fir is
        generic (
            DATA_WIDTH : integer := 11
        );
        port (
            CLK   : in  std_logic;
            RST   : in  std_logic;
            WR_EN : in  std_logic;
            D     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
            Q     : out std_logic_vector(DATA_WIDTH-1 downto 0)
        );
    end component;

    component ff is
        Port (
            D     : in  STD_LOGIC;    -- Data input
            CLK   : in  STD_LOGIC;    -- Clock input
            Q     : out STD_LOGIC    -- Output
        );
    end component;
    
    -- Shift register for input samples
    --type sample_array is array (0 to 10) of std_logic_vector(10 downto 0);
    signal shift_reg : sample_array := (others => (others => '0'));
    signal coeffs : coeff_array := (others => (others => '0'));
    -- Accumulator for filtering operation
    signal accum : signed(21 downto 0) := (others => '0');
    signal VIN_REG : std_logic := '0';
    signal VOUT_REG : std_logic := '0';
    --signal VOUT_cap : std_logic_vector(10 downto 0) := (others => '0');
    signal accum_11 : std_logic_vector(10 downto 0);  -- 11-bit signed signal
    --signal accum_int : integer := 0;

begin
    EN: ff   -- need to be changed
    port map (
        D   => VIN,
        CLK => CLK,
        Q   => VIN_REG
    );           
    -- Assign the coefficients
    coff:process (B0, B1, B2, B3, B4, B5, B6, B7, B8, B9, B10)
    begin 
            coeffs(0) <= B0;
            coeffs(1) <= B1;
            coeffs(2) <= B2;
            coeffs(3) <= B3;
            coeffs(4) <= B4;
            coeffs(5) <= B5;
            coeffs(6) <= B6;
            coeffs(7) <= B7;
            coeffs(8) <= B8;
            coeffs(9) <= B9;
            coeffs(10) <= B10;     
    end process;
    -- Main FIR filter process
    process(CLK, RST_n)
    begin
        if rising_edge(CLK) then
            if VIN = '1' then
                -- Shift input samples
                for i in 10 downto 1 loop
                    shift_reg(i) <= shift_reg(i-1);
                end loop;
                shift_reg(0) <= DIN;
            end if;
        end if;
    end process; 
    FUNC: process(VIN_REG, shift_reg, coeffs)  -- need to be changed
    begin 
        if VIN_REG = '1' then
                -- FIR filter operation
                accum_11 <= std_logic_vector(to_signed(to_integer(fir(shift_reg,coeffs)), 11));    
                VOUT_REG <= '1';  -- Assign the output signal
        else
            accum_11 <= (others => '0');
            VOUT_REG <= '0';  -- Reset the output signal
        end if;  
    end process;
    -- Output data 
    output_data : reg_fir
        generic map (
            DATA_WIDTH => 11
        )
        port map (
            CLK   => CLK,
            RST   => RST_n,
            WR_EN => VOUT_REG,
            D     => accum_11,
            Q     => DOUT
        );  
    output_valid : ff   -- need to be changed
        port map (
            D   => VOUT_REG,
            CLK => CLK,
            Q   => VOUT
        );                                    
end Behavioral;
