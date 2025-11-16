clear;
close all;

% Results directory
top_dir = "C:\Users\irvinelabuser\Documents\Isaac\2025_10_22\OTA_outdoors_v7.5_fixedAGCPtr13\10.0m_to_0.5m\Logs_binary_results";

% Plot options
save_plots = false;
mag_plot = true;
ch_maps_plot = false;
phase_plot = true;
ppm_plot = true;
split_mag_plot = false;
mag_plot_over_proc = true;
phase_plot_over_proc = true;

% extract dataset name
set_name_arr = split(top_dir,"\");
set_name = set_name_arr(length(set_name_arr)-1);

cd(top_dir)

dir_list = dir("Binary*");

result_list = strings(1,length(dir_list));

for i = 1:length(dir_list)
    result_list(i) = dir_list(i).name(15:end);
end

result_list_int = int32(str2double(result_list));

result_list_sorted = sort(result_list_int) + 1;

IQ_init_sorted_mat = NaN(result_list_sorted(end),80);
IQ_refl_sorted_mat = NaN(result_list_sorted(end),80);
Qual_init_sorted_mat = NaN(result_list_sorted(end),80);
Qual_refl_sorted_mat = NaN(result_list_sorted(end),80);

Freq_offset_mat = NaN(result_list_sorted(end),1);

channel_maps = zeros(80,1);

% Data compiling
for i = (result_list_sorted - 1)

    load(top_dir + "\Binary_result_" + i + "\IQ_Initiator.mat")
    load(top_dir + "\Binary_result_" + i + "\Ch_Initiator.mat")
    load(top_dir + "\Binary_result_" + i + "\IQ_Reflector.mat")
    load(top_dir + "\Binary_result_" + i + "\Ch_Reflector.mat")
    load(top_dir + "\Binary_result_" + i + "\Freq_offset_Initiator.mat")
    load(top_dir + "\Binary_result_" + i + "\Qual_Initiator.mat")
    load(top_dir + "\Binary_result_" + i + "\Qual_Reflector.mat")
    
    [IQ_init_sorted, Ch_init_sorted] = order(IQ_Initiator, Ch_Initiator);
    [IQ_refl_sorted, Ch_refl_sorted] = order(IQ_Reflector, Ch_Reflector);
    [Qual_init_sorted, trash1] = order(Qual_Initiator, Ch_Initiator);
    [Qual_refl_sorted, trash2] = order(Qual_Reflector, Ch_Reflector);
    
    IQ_init_dict = dictionary(Ch_init_sorted,IQ_init_sorted);
    IQ_refl_dict = dictionary(Ch_refl_sorted,IQ_refl_sorted);
    Qual_init_dict = dictionary(Ch_init_sorted,Qual_init_sorted);
    Qual_refl_dict = dictionary(Ch_refl_sorted,Qual_refl_sorted);

    for n = Ch_init_sorted
        IQ_init_sorted_mat(i+1,n) = IQ_init_dict(n);
        IQ_refl_sorted_mat(i+1,n) = IQ_refl_dict(n);
        channel_maps(n) = channel_maps(n) + 1;
        Qual_init_sorted_mat(i+1,n) = Qual_init_dict(n);
        Qual_refl_sorted_mat(i+1,n) = Qual_refl_dict(n);
    end
    Freq_offset_mat(i+1) = Freq_offset_Initiator(1);
end

% Magnitude plots
if mag_plot
    IQ_init_mags = NaN(result_list_sorted(end),80);
    IQ_refl_mags = NaN(result_list_sorted(end),80);
    IQ_init_rssi = NaN(result_list_sorted(end),80);
    IQ_refl_rssi = NaN(result_list_sorted(end),80);
    for i = result_list_sorted
        IQ_init_mags(i,:) = calc_mag(IQ_init_sorted_mat(i,:));
        IQ_refl_mags(i,:) = calc_mag(IQ_refl_sorted_mat(i,:));
        IQ_init_rssi(i,:) = calc_rssi(IQ_init_sorted_mat(i,:));
        IQ_refl_rssi(i,:) = calc_rssi(IQ_refl_sorted_mat(i,:));
    end
    f1 = figure(1);
    subplot(2,2,1);
    plot(IQ_init_mags.')
    xlabel("Channel #")
    ylabel("Magnitude")
    title(["Initiator IQ Magnitude";set_name],"Interpreter","none")
    subplot(2,2,2);
    plot(IQ_refl_mags.')
    xlabel("Channel #")
    ylabel("Magnitude")
    title("Reflector IQ Magnitude")
    subplot(2,2,3);
    plot(IQ_init_rssi.')
    xlabel("Channel #")
    ylabel("Magnitude (dBm)")
    title("Initiator IQ Magnitude (dBm)")
    subplot(2,2,4); 
    plot(IQ_refl_rssi.')
    xlabel("Channel #")
    ylabel("Magnitude (dBm)")
    title("Reflector IQ Magnitude (dBm)")
end

% Cumulative channel map plot
if ch_maps_plot
    f2 = figure(2);
    bar(channel_maps)
    title(["Cumulative Channel Map"; set_name],"Interpreter","none")
    xlabel("Channel #")
    ylabel("Channel Available")
end

% PCT Phase plot
if phase_plot
    PCT_phase_normed = NaN(result_list_sorted(end),80);
    for i = result_list_sorted
        PCT_phase_normed(i,:) = norm(calc_phase(IQ_init_sorted_mat(i,:),IQ_refl_sorted_mat(i,:)),2);
    end
    f3 = figure(3);
    plot(PCT_phase_normed.')
    title(["PCT product phase"; "('normalized': all lines starting at 0)"; set_name],"Interpreter","none")
    xlabel("Channel #")
    ylabel("Phase unwrapped")
end

% PPM plot
if ppm_plot
    f4 = figure(4);
    scatter(1:result_list_sorted(end),Freq_offset_mat)
    title(["PPM per procedure"; set_name],"Interpreter","none")
    xlabel("Procedure #")
    ylabel("PPM offset")
end

% I and Q magnitude plots
if split_mag_plot
    split_mag_ch = 40;
    f5 = figure(5);
    subplot(2,1,1)
    plot(real(IQ_init_sorted_mat(:,split_mag_ch)))
    title(["Initiator I magnitude at channel " + split_mag_ch; set_name],"Interpreter","none")
    xlabel("Procedure #")
    ylabel("Magnitude")
    subplot(2,1,2)
    plot(imag(IQ_init_sorted_mat(:,split_mag_ch)))
    title("Initiator Q magnitude at channel " + split_mag_ch)
    xlabel("Prodecure #")
    ylabel("Magnitude")
end

% Magnitude over procedure plot
if mag_plot_over_proc
    mag_init_over_proc = calc_mag(IQ_init_sorted_mat);
    rssi_init_over_proc = calc_rssi(IQ_init_sorted_mat);
    proc_mag_ch = 40;
    f6 = figure(6);
    subplot(2,1,1)
    plot(mag_init_over_proc)
    title(["Initiator magnitude over procedure by channel"; set_name],"Interpreter","none")
    xlabel("Procedure #")
    ylabel("Magnitude")
    subplot(2,1,2)
    plot(rssi_init_over_proc)
    title("Initiator RSSI over procedure by channel")
    xlabel("Procedure #")
    ylabel("RSSI")
end

% Phase plot over procedures
if phase_plot_over_proc
    PCT_phase = NaN(result_list_sorted(end), 80);
    PCT_phase_normed_over_proc = NaN(result_list_sorted(end),80);
    for i = result_list_sorted
        PCT_phase(i,:) = calc_phase(IQ_init_sorted_mat(i,:),IQ_refl_sorted_mat(i,:));
    end
    for n = 1:80
        PCT_phase_normed_over_proc(:,n) = PCT_phase(:,n) - PCT_phase(1,n);
    end
    proc_phase_ch = 40;
    f7 = figure(7);
    plot(PCT_phase_normed_over_proc)
    % plot(result_list_sorted,calc_phase(IQ_init_sorted_mat(:,proc_phase_ch),IQ_refl_sorted_mat(:,proc_phase_ch)))
    title(["Phase over procedures by channel "; set_name],"Interpreter","none")
    xlabel("Procedure #")
    ylabel("Phase (deg)")
end

% 

% Save plots
save_dir = top_dir(1:end-19);
cd ..\
if save_plots
    if mag_plot
        saveas(f1, "IQ_magnitude.png")
    end
    if ch_maps_plot
        saveas(f2, "channel_map.png")
    end
    if phase_plot
        saveas(f3, "PCT_product_phase.png")
    end
    if ppm_plot
        saveas(f4, "ppm_offset.png")
    end
    if split_mag_plot
        saveas(f5, "i_and_q_separate_magnitude.png")
    end
    if mag_plot_over_proc
        saveas(f6, "IQ_magnitude_over_procedures.png")
    end
end

function [X_sorted, Ch_sorted] = order(X,X_ch)
    X = X(1:(length(X)-1));
    X_ch = X_ch(1:(length(X_ch)-1));
    [Ch_sorted, idx] = sort(X_ch);
    X_sorted = X(idx);
end

function IQ_mag = calc_mag(IQ)
    IQ_prod = IQ .* conj(IQ);
    IQ_mag = sqrt(IQ_prod);
end

function rssi = calc_rssi(IQ)
    vrms2 = (IQ .* conj(IQ))/2;
    powerW = vrms2/50;
    powermW = powerW/1000;
    rssi = 10 .* log10(powermW);
end

function PCT_prod_phase = calc_phase(IQ_init, IQ_refl)
    PCT_prod = IQ_init .* IQ_refl;
    PCT_prod_phase = rad2deg(unwrap(phase(PCT_prod)/2));
end

function phase_normalized = norm(calcd_phase, idx)
    phase_normalized = calcd_phase - calcd_phase(idx);
end