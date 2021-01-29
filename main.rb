# fixtureWidth  -  31 1/16 in    790mm 
# fixtureHeight -  26 1/2 in     675mm
# glassWidth    -  32 5/16 in    820mm
# glassHeight   -  26 13/16 in   680mm
# lightLength   -  21 in         535mm
# bulbCount     -  8
# sideMargin    -  0mm


class Fixture
  attr_accessor :bulb_limit, :bulb_glass_distance, :bulb_to_edge_margin, :glass_surface, :bulbs, :light_spacing

  def initialize(bulb_limit, bulb_glass_distance, bulb_to_edge_margin)
    @bulb_edge_margin = bulb_to_edge_margin
    @bulb_limit = bulb_limit
    @bulb_glass_distance = bulb_glass_distance
    @bulbs = []
    @glass_width = 832 #mm
    @glass_surface = glass_width.times.map { |x| 0 }
    @light_spacing = nil
  end

  def add_bulb(bulb)
    bulb_count = self.bulbs.length
    if bulb_count < @bulb_limit
      @bulbs.append(bulb)
      bulb.sequence = @bulbs.length
      bulb.fixture = self
      bulb.surface_effect = @glass_width.times.map { |x| 0 }
    end
  end

  def glass_width
    return @glass_width
  end

  def align_lights
    return nil if self.bulbs.length == 0

    # light spacing will be as follows
    # | margin | lightspace | *light* | lightspace | *light* | lightspace | margin |
    @light_spacing = (@glass_width / (@bulbs.length + 1))
    
    position = 0
    self.bulbs.each_with_index { |bulb, index| 
      position = position + @light_spacing
      bulb.position = position
    }
  end

  def output_file(filename)
    require 'csv'

    CSV.open(filename, "w") do |csv|
      self.glass_surface.each { |cell|
        csv << [cell]
      }
    end
  end
end

class Bulb
  attr_accessor :position, :sequence, :surface_effect, :fixture, :brightness

  def initialize(brightness=100)
    @position = nil
    @sequence = nil
    @surface_effect = nil
    @brightness = brightness
  end

  def identify
    if self.fixture.nil?
      puts "I am a bulb with no fixture!"
    else
      puts "I'm bulb number #{@sequence} in position #{@position}."
    end
  end

  def calculate_effect
    if !@surface_effect.nil?
      # cycle through each cell and calculate the intensity drop relative to the home cell
      @surface_effect.each_with_index { |cell, index|
        h_length = (self.position - (index + 1)).abs
        v_length = self.fixture.bulb_glass_distance
        hypotenuse_length = get_hypotenuse(v_length, h_length)
        self.surface_effect[index] = intensity_drop(v_length, hypotenuse_length, self.brightness)
      }
      
    end
  end

  def apply_effect
    self.surface_effect.each_with_index { |cell, index|
      self.fixture.glass_surface[index] += cell
    }
    
    #puts "number of positions on the glass: #{fixture.glass_surface.length}"
    #puts "number of positions on the bulb: #{fixture.bulbs[0].surface_effect.length}"
    #fixture.bulbs.each { |bulb|
    
    #}
  end

end

def get_hypotenuse(v_leg, h_leg)
  return Integer.sqrt((v_leg ** 2) + (h_leg ** 2))
end

def intensity_drop(distance_1, distance_2, intensity=100)
  return (intensity * distance_1 ** 2) / (distance_2 ** 2)
end




# need to create an array of intensity percentages for each division of the glass width for each bulb
# take a bulb,  calculate the distance between the source and the first glass division
# the distance is calculated as the hypotenuse of a right triangle
# one side of triangle is the distance between the bulb and the glass
# the second side of the triangle is the distance between the bulb lateral position and the current glass division
# plug the two distances into the calculate_intensity_drop function

#new_intensity = calculate_intensity_drop(glass_bulb_distance, 40)

distances = [100, 200, 300, 400, 500, 600, 700, 800, 900, 1000]

distances.each { |distance|
  #bulb_limit, bulb_glass_distance, bulb_to_edge_margin
  fixture = Fixture.new(7, distance, 0)

  fixture.bulb_limit.times { |index|
    if index == 4
      new_bulb = Bulb.new(1)
    else
      new_bulb = Bulb.new
    end
    fixture.add_bulb(new_bulb)
  }

  fixture.align_lights
  #puts "Light spacing: #{fixture.light_spacing}"
  fixture.bulbs.each { |bulb| 
    #puts bulb.position
    bulb.calculate_effect 
    bulb.apply_effect
  }

  fixture.output_file("#{distance}.csv")
}