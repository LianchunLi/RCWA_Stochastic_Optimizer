
function [Ref, Tran] = simulate_structure_anisotropic(structure, lambda,...
    theta,  Num_ord, e)
    e0=8.854187817e-12;
    c0 = 299792458;                             % speed of light in space, [m/s]
    %wn = linspace(3500,25000,300) ; % wavenumber, [1/cm]
    w = 1e6*2*pi*c0./lambda;            % angular frequency, [rad/s]

    %% start simulation
    d  = structure.layer_thicknesses;
    N = length(d);                                   % # of layers
    Ref = []; Tran = [];

    %% get properties that are not frequency dependent
    [f, periods] = structure.convert_to_RCWA();
    
    %% enter wavelength loop: cannot do any frequency dependence here
    for i =1:length(lambda)  %um microns
        
        for layer = 1:structure.num_layers
              eps_tensors = structure.layer_dielectric_tensors{layer};
              structure_specification = structure.layer_structures{layer};
              % create dielectric    
              for ribbon = 1:length(structure_specification)
                  eps = eps_tensors{ribbon};
                  e_m_x{layer}(ribbon) =  eps(1,1,i);
                  e_m_y{layer}(ribbon) =  eps(2,2,i);
                  e_m_z{layer}(ribbon) =  eps(3,3,i);
              end

        end %exit layer loop

        [Ref(i), Tran(i)] = RCWA_Multi_TM(N, e_m_x,e_m_y,e_m_z,f, periods, d, e, ...
            lambda(i), theta, Num_ord); 
        %disp(strcat('lambda=',num2str(lambda(i)),', R=', num2str(Ref(i)), ', T= ', num2str(Tran(i))));
    
    end
    
end


