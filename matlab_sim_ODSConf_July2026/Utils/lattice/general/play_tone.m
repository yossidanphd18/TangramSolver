function play_tone(f0, duration_mins, fs)
    % f0 = 440;
	duration_sec = duration_mins*60;
	total_samples = fs * duration_sec;
	t = linspace(0, duration_sec, total_samples); % Time vector for 60 seconds
	waveform = 0.8 * sin(2 * pi * f0 * t);
	sound(waveform, fs);
end
