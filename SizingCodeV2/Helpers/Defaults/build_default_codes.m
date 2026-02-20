function codes = build_default_codes()

    codes = struct();
    % LIST OF UNIQUE NUMBERS TO ASSIGN TO THINGS FOR EASY COMPARISON (good bit faster than comparing strings)

    codes.CD0_BASIC = 101; % uses an empty weight correllation to predict Swet and applys a fixed 
    codes.CD0_IGNORE = 102; % sets CD0 to 0

    codes.CDw_BASIC = 201;
    codes.CDw_AWAVE = 202;
    
    codes.PROP_BASIC = 301;
    codes.PROP_NPSS = 302;

    codes.CDi_BASIC_SUBSONIC = 401;
    codes.CDi_IGNORE = 402;

    codes.CLa_BASIC = 501;

    codes.COST_BASIC = 601;
    codes.COST_XANDERSCRIPT = 602;

    codes.PROP_BASIC = 701;

    codes.CDp_CONST = 801; % payload drag -> all payloads have the same CD0
    codes.CDp_IGNORE = 802;

    codes.SpotFactor_BASIC = 1001;

    % Override codes for the model class
    codes.OVER_NONE = 900; % just kidding don't override anything
    codes.OVER_NO_WRITE = 901; % 1 = don't bother writing this to memory (ignored if there is already a value in memory)
    codes.OVER_NO_READ = 902; % 2 = don't read from the memory
    codes.OVER_NO_READ_NO_WRITE = 903; % 3 = don't read from the memory and don't write (this is a one off call)

    codes.MISSILE = 10;
    codes.BOMB = 11;
    codes.TANK = 12;
    codes.POD = 13;
end