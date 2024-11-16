% BER Analysis Test Script
clear all;
close all;

% Test parameters
SNRdB = 0:2:20;          % SNR range in dB
numBits = 1e5;           % Number of bits to simulate

% Define all modulation types and their orders
modulations = {
    'BPSK', 2;
    'QPSK', 4;
    'QAM',  16;
    'QAM',  64
};

% Define channel types
channels = {'AWGN', 'Rayleigh', 'Rician'};

% Create figure for combined plots
figure('Position', [100 100 1200 800]);

% Color and marker definitions for different modulations
colors = {'b', 'r', 'g', 'm'};
markers = {'o', 's', 'd', '^'};
linestyles = {'-', '--', ':'};

% Store legend entries
legendEntries = {};

% Loop through channel types
for c = 1:length(channels)
    % Create subplot for each channel type
    subplot(1, 3, c);
    hold on;
    grid on;
    
    % Loop through modulation schemes
    for m = 1:size(modulations, 1)
        % Create analyzer object
        modType = modulations{m, 1};
        M = modulations{m, 2};
        channelType = channels{c};
        
        fprintf('Testing %s M=%d in %s channel...\n', modType, M, channelType);
        
        % Create analyzer
        analyzer = BERAnalyzer(modType, M, SNRdB, numBits, channelType);
        
        % Perform analysis
        [ber, theoretical] = analyzer.analyzeBER();
        
        % Plot results
        semilogy(SNRdB, ber, [colors{m} markers{m} '-'], 'LineWidth', 1.5, ...
                'DisplayName', sprintf('Sim %s M=%d', modType, M));
        semilogy(SNRdB, theoretical, [colors{m} linestyles{2}], 'LineWidth', 1.5, ...
                'DisplayName', sprintf('Theory %s M=%d', modType, M));
        
        % Store legend entries for first channel only
        if c == 1
            legendEntries = [legendEntries, ...
                           {sprintf('Sim %s M=%d', modType, M), ...
                            sprintf('Theory %s M=%d', modType, M)}];
        end
        
        % Save data for later analysis
        results(c,m).modType = modType;
        results(c,m).M = M;
        results(c,m).channelType = channelType;
        results(c,m).ber = ber;
        results(c,m).theoretical = theoretical;
    end
    
    % Configure subplot
    xlabel('SNR (dB)');
    ylabel('Bit Error Rate (BER)');
    title(['BER Performance in ' channelType ' Channel']);
    ylim([1e-5 1]);
    grid on;
    
    % Add legend to first subplot only
    if c == 1
        legend('Location', 'southwest');
    end
end

% Adjust figure layout
sgtitle('BER Performance Analysis Across Different Channels and Modulations');

% Print performance analysis
fprintf('\nPerformance Analysis Summary:\n');
fprintf('===========================\n');

for c = 1:length(channels)
    fprintf('\nChannel Type: %s\n', channels{c});
    fprintf('----------------\n');
    
    for m = 1:size(modulations, 1)
        % Calculate mean BER improvement per dB
        ber = results(c,m).ber;
        snr_points = SNRdB(2:end);
        ber_improvement = -diff(log10(ber));
        avg_improvement = mean(ber_improvement);
        
        fprintf('%s M=%d:\n', results(c,m).modType, results(c,m).M);
        fprintf('  - BER range: %.2e to %.2e\n', max(ber), min(ber));
        fprintf('  - Average BER improvement per dB: %.2f orders\n', avg_improvement);
        
        % Find SNR required for BER = 10^-4
        target_ber = 1e-4;
        snr_index = find(ber < target_ber, 1);
        if ~isempty(snr_index)
            fprintf('  - SNR required for BER = 10^-4: %.1f dB\n', SNRdB(snr_index));
        else
            fprintf('  - SNR required for BER = 10^-4: >%.1f dB\n', max(SNRdB));
        end
    end
end

% Save results to file
save('ber_analysis_results.mat', 'results', 'SNRdB', 'modulations', 'channels');

% Create performance comparison table
fprintf('\nPerformance Comparison Table at SNR = 10dB:\n');
fprintf('=========================================\n');
fprintf('Modulation\t|\tAWGN\t|\tRayleigh\t|\tRician\n');
fprintf('---------------------------------------------------------\n');

snr_index = find(SNRdB == 10);
if ~isempty(snr_index)
    for m = 1:size(modulations, 1)
        fprintf('%s M=%d\t|\t%.2e\t|\t%.2e\t|\t%.2e\n', ...
            modulations{m,1}, modulations{m,2}, ...
            results(1,m).ber(snr_index), ...
            results(2,m).ber(snr_index), ...
            results(3,m).ber(snr_index));
    end
end

% Additional Analysis Plots

% Plot 1: BER vs Modulation Order at fixed SNR
figure;
snr_points = [5, 10, 15];  % Selected SNR points
mod_orders = [2, 4, 16, 64];
markers = {'o', 's', 'd'};

for s = 1:length(snr_points)
    snr_index = find(SNRdB == snr_points(s));
    if ~isempty(snr_index)
        for c = 1:length(channels)
            ber_at_snr = zeros(1, length(mod_orders));
            for m = 1:size(modulations, 1)
                ber_at_snr(m) = results(c,m).ber(snr_index);
            end
            semilogy(1:length(mod_orders), ber_at_snr, [markers{c} '-'], ...
                    'DisplayName', sprintf('%s @ %ddB', channels{c}, snr_points(s)));
            hold on;
        end
    end
end

xlabel('Modulation Index');
ylabel('BER');
title('BER vs Modulation Order at Different SNR Points');
set(gca, 'XTick', 1:length(mod_orders));
set(gca, 'XTickLabel', {'BPSK', 'QPSK', '16-QAM', '64-QAM'});
grid on;
legend('Location', 'northwest');

% Plot 2: SNR Required for Target BER
figure;
target_ber = 1e-4;
req_snr = zeros(length(channels), size(modulations, 1));

for c = 1:length(channels)
    for m = 1:size(modulations, 1)
        ber = results(c,m).ber;
        snr_index = find(ber < target_ber, 1);
        if ~isempty(snr_index)
            req_snr(c,m) = SNRdB(snr_index);
        else
            req_snr(c,m) = max(SNRdB);
        end
    end
end

bar(req_snr');
xlabel('Modulation Scheme');
ylabel('Required SNR (dB)');
title(sprintf('Required SNR for BER < %.0e', target_ber));
set(gca, 'XTickLabel', {'BPSK', 'QPSK', '16-QAM', '64-QAM'});
legend(channels);
grid on;