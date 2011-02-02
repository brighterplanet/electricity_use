# Copyright © 2010 Brighter Planet.
# See LICENSE for details.
# Contact Brighter Planet for dual-license arrangements.
require 'leap'
require 'timeframe'
require 'date'
require 'weighted_average'
require 'builder'

## ElectricityUse carbon model
# This model is used by [Brighter Planet](http://brighterplanet.com)'s carbon emission [web service](http://carbon.brighterplanet.com) to estimate the **greenhouse gas emissions of electricity use**.
#
##### Timeframe and date
# The model estimates the emissions that occur during a particular `timeframe`. To do this it needs to know the `date` on which the electricity use occurred. For example, if the `timeframe` is January 2010, a electricity use that occurred on January 5, 2010 will have emissions but a electricity use that occurred on February 1, 2010 will not.
#
##### Calculations
# The final estimate is the result of the **calculations** detailed below. These calculations are performed in reverse order, starting with the last calculation listed and finishing with the `emission` calculation. Each calculation is named according to the value it returns.
#
##### Methods
# To accomodate varying client input, each calculation may have one or more **methods**. These are listed under each calculation in order from most to least preferred. Each method is named according to the values it requires. If any of these values is not available the method will be ignored. If all the methods for a calculation are ignored, the calculation will not return a value. "Default" methods do not require any values, and so a calculation with a default method will always return a value.
#
##### Standard compliance
# Each method lists any established calculation standards with which it **complies**. When compliance with a standard is requested, all methods that do not comply with that standard are ignored. This means that any values a particular method requires will have been calculated using a compliant method, because those are the only methods available. If any value did not have a compliant method in its calculation then it would be undefined, and the current method would have been ignored.
#
##### Collaboration
# Contributions to this carbon model are actively encouraged and warmly welcomed. This library includes a comprehensive test suite to ensure that your changes do not cause regressions. All changes should include test coverage for new functionality. Please see [sniff](http://github.com/brighterplanet/sniff#readme), our emitter testing framework, for more information.
module BrighterPlanet
  module ElectricityUse
    module CarbonModel
      def self.included(base)
        base.decide :emission, :with => :characteristics do
          ### Emission calculation
          # Returns the `emission` estimate in *kg CO<sub>2</sub>e*.
          # This is the user's share of the total electricity generation emissions that occurred during the `timeframe`.
          committee :emission do
            quorum 'from emission factor and energy', :needs => [:emission_factor, :energy] do |characteristics|
              characteristics[:energy] * characteristics[:emission_factor]
            end
          end
          
          ### emission factor calculation
          # Returns the emission factor of the electricity source
          committee :emission_factor do # returns kg co2e / kWh
            quorum 'from eGRID subregion', :needs => :egrid_subregion do |characteristics|
              characteristics[:egrid_subregion].electricity_emission_factor
            end
          end
          
          ### eGRID subregion calculation
          # Returns the [eGRID subregion](http://data.brighterplanet.com/egrid_subregions) where electricity was used.
          committee :egrid_subregion do
            #### eGRID subregion from zip code
            # **Complies:** GHG Protocol, ISO 14064-1, Climate Registry Protocol
            #
            # Looks up the [zip code](http://data.brighterplanet.com/zip_codes) `eGRID subregion`.
            quorum 'from zip code', :needs => :zip_code, :complies => [:ghg_protocol, :iso, :tcr] do |characteristics|
              characteristics[:zip_code].egrid_subregion
            end
            
            #### Default eGRID subregion
            # **Complies:** GHG Protocol, ISO 14064-1, Climate Registry Protocol
            #
            # Uses an artificial [eGRID subregion](http://data.brighterplanet.com/egrid_subregions) that represents the U.S. average.
            quorum 'default', :complies => [:ghg_protocol, :iso, :tcr] do
              EgridSubregion.find_by_abbreviation 'US'
            end
          end

          ### energy
          # Returns the number of kilowatt-hours of electricity used (can be input by client)
          committee :energy do
            #### Default energy 
            # Uses the 2008 US American [annual household average](http://www.eia.doe.gov/ask/electricity_faqs.asp#electricity_use_home)
            quorum 'default' do
              11_040
            end
          end
          
          ### Zip code
          # Returns the client-input [zip code](http://data.brighterplanet.com/zip_codes).
        end
      end
    end
  end
end
