#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

# set the period for weighted moving average
AVG_PERIOD = 20

def get_temps
  begin
    cpu_temp = `sensors`[/Composite.*?(\d+.\d)/, 1]
  rescue Errno::ENOENT
    puts 'ERROR: need to install lm_sensors'
    return nil
  end
  begin
    gpu_temp = `nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader`
  rescue
    puts 'ERROR: need to install nvidia-utils'
    return nil
  end
  return {'cpu' => cpu_temp.to_f, 'gpu' => gpu_temp.chomp.to_f}
end

def show_temps
  avgs = {'cpu' => 0, 'gpu' => 0}
  prev_temps = {'cpu' => [], 'gpu' => []}
  temps = get_temps
  if temps == nil
    exit
  end

  begin
    while true
      temps.keys.each do |key|
        prev_temps[key] << temps[key]
        length = prev_temps[key].length
        if length > AVG_PERIOD
          prev_temps[key].shift
          length = AVG_PERIOD
        end
        numerator = 0
        0.upto(length - 1) do |x|
          numerator += prev_temps[key][x] * (x + 1)
        end
        denominator = length * (length + 1) / 2
        avgs[key] = numerator / denominator
      end
      print(
        "\rcpu: #{avgs['cpu'].round()}  gpu: #{avgs['gpu'].round()} "
      )
      sleep 0.25
      temps = get_temps
    end
  rescue Interrupt
    puts ''
    exit
  end
end

# run as 'ruby temps.rb'; ctrl-c to exit
show_temps
