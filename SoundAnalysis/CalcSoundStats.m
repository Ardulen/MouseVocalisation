function [S, P, Waveform] = CalcSoundStats(varargin)

global CG
if ~exist('CG','var') || isempty(CG) || ~isfield(CG,'Parameters'); C_setupEnvironment; end


P = parsePairs(varargin);
checkField(P, 'audio_sr', 250000) % Hz
checkField(P, 'StimMinF', 2000) % Hz
checkField(P, 'StimMaxF', 64000) % Hz
checkField(P, 'low_audio_f', 500) % Hz
checkField(P, 'hi_audio_f', 64000) % Hz
checkField(P, 'low_mod_f', 1) % Hz
checkField(P, 'hi_mod_f', 40) % Hz
checkField(P, 'max_orig_dur_s', 10) % Sample length to generate for initial stats estimate
checkField(P, 'RealizationDurS', nan) % Duration of each Realization (should be >= max trial length)
checkField(P, 'NRealizations', nan)
checkField(P, 'lin_or_log_filters',2); %1--> log acoustic & mod; 2--> log acoust, lin mod; 3--> lin acoust, log mod; 4--> lin acoust, lin mod
checkField(P, 'N_mod_channels', 200) % Number modulation filters
checkField(P, 'N_audio_channels', 36) % Number of acoustic filters used excluding lowpass and highpass filters on ends of spectrum
checkField(P, 'env_sr', 25000) % Hz
checkField(P, 'TORC', 1)
checkField(P, 'output_folder', [CG.Files.DataPath,'StatisticallyDefinedNoise\'])
checkField(P, 'orig_sound_folder', [P.output_folder,'OriginalSounds\']);
checkField(P, 'template_folder', P.orig_sound_folder);
checkField(P, 'initial_sound_folder', P.orig_sound_folder);
checkField(P, 'MaxSynthesisIterations', 30); 
checkField(P, 'desired_synth_dur_s', nan); % Duration of synthesized sound 
checkField(P, 'env_sr', 25000) % Hz
checkField(P, 'FIG', 100)
checkField(P, 'Corrs', [0, 0.8])
checkField(P, 'Vars', [0.02, 0.4])

checkField(P);

% Default options for remaining parameters
P = NoiseSynthesisParameters(P); 
for i = 1:numel(P.Corrs)
    WaveandFS=load(['/home/experimenter/dnp-backup/2pTestingJanek/TORCNoise/TORCNoise_corr', num2str(P.Corrs(i)), '_var', num2str(P.Vars(i)), '_real', num2str(2), '.mat']);
    Waveform{i} = WaveandFS.NoiseWaveform;

    S{i} = measure_texture_stats(Waveform{i}, P);
end