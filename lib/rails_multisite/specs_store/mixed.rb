module RailsMultisite

  module SpecsStore

    class Mixed < Base

      def initialize ( strategies )

        @strategies = strategies

      end

      def find_by_host ( host )

        @strategies.each do | strategy |

          spec = strategy.find_by_host host

          return spec if spec

        end

        nil

      end

      def find_by_name ( name )

        @strategies.each do | strategy |

          spec = strategy.find_by_name name

          return spec if spec

        end

        nil

      end

      def each ( &block )

        @strategies.each do | strategy |

          strategy.each &block

        end

      end

      def include_named? ( name )

        @strategies.any? do | strategy |

          strategy.include_named? name

        end

      end

      def names

        @strategies.map( &:names ).flatten

      end

      def databases

        @strategies.map( &:databases ).reduce( &:merge )

      end

    end

  end

end
