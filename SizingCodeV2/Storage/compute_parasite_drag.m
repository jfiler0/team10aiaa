function CD0 = compute_parasite_drag(plane, model)

    % 1. Compute the wetted area using a regression based on empty weight. All models need this
    % what units is this in??
    c = -0.1289; d = 0.7506; % Regression from somewhere lol
    S_wet = SWET_Scalar * 0.09290304*(10^c  * N2lb(plane.WE)^d);

    % 2. Choose how to calculate CD0
    switch model
        case(1) % old parasite drag prediction
            
            Cf = 0.004; % Raymer gives this value for navy fighters
            CD0 = Cf * S_wet/plane.S_ref;
        case(2) % new parasite drag prediction using friction.m from config aero
            CD0 = friction_comp(1E6, 0.5, 0, 0, 1, plane.S_ref);
    end

end

function [CD, CDFORM, CDTOTAL] =  friction_comp(Re, M, type, Ftrans, refl, S_ref)

    % if type = 0 -> planar
    % if type = 1 -> body of revolution

    % Ftrans = input('Transitional flow (0:turb, 1:lam, ratio:lam/turb)? ');
    
    % refl -> reference length of whatever body is being considered (mean length of the surface)
    
    RN = Re; % Reynolds Number / Length
    Xme = M;
    
    TwTaw = 1;
    
    % set for factor based on T/C or d/l (decided by Icode)
    %whm modified constants in Feb. 2006, 2.7 was 1.8, 100 was 50 - 
    if (type == 0) % PLANAR
        FF = 1 + 2.7*TC(Comp) + 100*TC(Comp)^4;
    else
        FF = 1 + 1.5*TC(Comp)^1.5 + 7*TC(Comp)^3;
    end
    
    Rex = RN*refl;
    % determine laminar drag coefficient
    % lamcf;
        g = 1.4;
        Pr = 0.72;
        R = sqrt(Pr);
        TE = 390;
        TK = 200;
        
        TwTe = TwTaw*(1 + R*(g - 1)*Xme^2/2);
        TstTe = 0.5 + 0.039*Xme^2 + 0.5*TwTe;
        
        cstar = sqrt(TstTe)*(1 + TK/TE)/(TstTe + TK/TE);
        
        Cf = 2*0.664*sqrt(cstar)/sqrt(Rex(Comp));
    Cflam = Cf;
    % determine turbulent drag coefficient
    % turbcf;
        epsmax = 0.1e-8;
        g = 1.4;
        r = 0.88;
        Te = 222;
        
        xm = (g-1)*Xme^2/2;
        TawTe = 1 + r*xm;
        F = TwTaw*TawTe;
        Tw = F*Te;
        A = sqrt(r*xm/F);
        B = (1 + r*xm - F)/F;
        denom = sqrt(4*A^2 + B^2);
        Alpha = (2*A^2 - B)/denom;
        Beta = B/denom;
        Fc = ((1 + sqrt(F))/2)^2;
        
        if (Xme > 0.1)
            Fc = r*xm/((asin(Alpha) + asin(Beta))^2);
        end
        
        Xnum = (1 + 122*10^(-5/Tw)/Tw);
        Denom = (1 + 122*10^(-5/Te)/Te);
        Ftheta = sqrt(1/F)*(Xnum/Denom);
        Fx = Ftheta/Fc;
        RexBar = Fx*Rex(Comp);
        Cfb = 0.074/(RexBar^0.2);
        
        iter = 0;
        eps = 1;
        
        while (eps>epsmax)
            iter = iter + 1;
            if (iter>200)
                disp('Did not converge');
            end
                Cfo = Cfb;
                Xnum = 0.242 - sqrt(Cfb)*log10(RexBar*Cfb);
                Denom = 0.121 + sqrt(Cfb)/log(10);
                Cfb = Cfb*(1 + Xnum/Denom);
                eps = abs(Cfb-Cfo);
        end
        
        Cf = Cfb/Fc;
    Cfturb = Cf;
    
    % determine total drag, doesn't change if Ftrans = 0
    CFI = Cfturb - Ftrans*(Cfturb - Cflam);
    CFSW = CFI*swet;
    CFSWFF = CFSW*FF;
    % CDCOMP = CFSWFF/S_ref;
    
    % Sum1 = sum(CFSW);
    % Sum2 = sum(CFSWFF);
    % Sum3 = sum(CDCOMP);
    % 
    % % total form and friction drag for individual flight condition
    CD = CFSW/SREF;
    CDFORM = (CFSWFF-CFSW)/S_ref;
    CDTOTAL = CD + CDFORM;

end