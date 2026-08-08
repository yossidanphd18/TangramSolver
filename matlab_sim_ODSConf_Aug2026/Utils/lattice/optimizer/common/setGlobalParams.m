function [GP] = setGlobalParams(ProblemSpec, sim_params)

GP = [];

GP.challenge_type = sim_params.challenge_type;

GP.save_path_per_test = sim_params.save_path_per_test;

GP.clip2roi = sim_params.clip2roi;

GP.skip_preprocess = sim_params.skip_preprocess;
GP.inject_true_sol = sim_params.inject_true_sol;

GP.npcs = ProblemSpec.npcs;
GP.nrots = length(ProblemSpec.Grid.rot_angles);
GP.nflips = length(ProblemSpec.flip_ids);
GP.limit_nshapes = ProblemSpec.limit_nshapes;
GP.assumed_tmax  = ProblemSpec.assumed_tmax;
GP.im_width_pixels = ProblemSpec.im_width_pixels;
GP.db_save_folder_path = sim_params.db_save_folder_path;
GP.use_long_rect_dims = 0;
GP.use_equal_pixels_value = 1;

GP.flag_transform_type = sim_params.flag_transform_type;
GP.flag_selected_bins_mode = sim_params.flag_selected_bins_mode;

if(strcmp(sim_params.flag_selected_bins_mode,'dominant'))
    GP.flag_dominant_thresh = sim_params.flag_dominant_thresh;
end

GP.flag_complex_valued_optim = sim_params.flag_complex_valued_optim;

GP.flag_use_disqualified_db = sim_params.flag_use_disqualified_db;
GP.flag_use_true_rots = sim_params.flag_use_true_rots;
GP.flag_show_final_result_figure = sim_params.flag_show_final_result_figure;
GP.flag_use_true_sol_hint = sim_params.flag_use_true_sol_hint;
GP.flag_use_integer_ai = sim_params.flag_use_integer_ai;
GP.flag_have_true_ref = sim_params.flag_have_true_ref;
GP.gurobi_params_set_id = sim_params.gurobi_params_set_id;

% Set images dimension and nfft/nbins.

Nr_wo_pad = GP.im_width_pixels; % = 31 ;
Nc = Nr_wo_pad;
Nr_w_pad = Nr_wo_pad;
nfft = Nr_wo_pad * Nc;     

assert(Nr_wo_pad == Nc, 'image dims must be square!');
assert(mod(Nr_wo_pad, 2) == 1, 'image dims must be odd!');

GP.Nr_wo_pad = Nr_wo_pad;
GP.Nr_w_pad = Nr_w_pad;
GP.Nc = Nc;
GP.nfft = nfft;

if(0) % do this later on
    % select the bins to be used in optimization.
    [u_k, b_k] = selectOptimizationBins(nfft, GP);
    
    GP.u_k = u_k; % u_k bins indexing 0,1,2,3 
    GP.b_k = b_k; % b_k bins indexing 1,2,3,...
    
    % vectors dmension (complex for dft so 2*B).
    B = length(b_k);
    
    if(strcmp(sim_params.flag_transform_type,'dft'))
	    GP.nbins = B;
	    GP.vdim  = 2*B;
    else
	    GP.vdim  = B;
    end
end

if(GP.use_equal_pixels_value)
    if(GP.gurobi_params_set_id ~= 1)
       GP.pixel_values = 1*ones(1,300); % takes ~16 mins to solve the kangorro
    else
         if(strcmp(ProblemSpec.challenge_type,'polygons'))
             GP.pixel_values = 1*ones(1,300); % takes ~3 mins to solve the kangorro 
         else
             GP.pixel_values = 231*ones(1,300); % takes ~3 mins to solve the kangorro 
         end
    end
else
    GP.pixel_values = randi([35,1000],1,300);
end

end