require 'spec_helper'


describe Praxis::Mapper::SelectorGenerator do
  let(:resource) { SimpleResource }
  subject(:generator) {described_class.new }

  context '#add' do
    let(:resource) { SimpleResource }
    shared_examples 'a proper selector' do
      it { expect(generator.add(resource, fields).dump).to be_deep_equal selectors }
    end
    
    context 'basic combos' do
      context 'direct column fields' do
        let(:fields) { {id: true, foobar: true} }
        let(:selectors) do 
          {
            model: SimpleModel,
            columns: [:id, :foobar]
          } 
        end
        it_behaves_like 'a proper selector'
      end

      context 'aliased column fields' do
        let(:fields) { {id: true, name: true} }
        let(:selectors) do
          {
            model: SimpleModel,
            columns: [:id, :simple_name]
          }
        end
        it_behaves_like 'a proper selector'
      end

      context 'pure associations without recursion' do
        let(:fields) { {other_model: true} }
        let(:selectors) do
          {
            model: SimpleModel,
            columns: [:other_model_id], # FK of the other_model association
            tracks: {
              other_model: { 
                columns: [:id], # joining key for the association
                model: OtherModel 
              }
            }
          }
        end
        it_behaves_like 'a proper selector'
      end

      context 'aliased associations without recursion' do
        let(:fields) { {other_resource: true} }
        let(:selectors) do
          {
            model: SimpleModel,
            columns: [:other_model_id], # FK of the other_model association
            tracks: {
              other_model: { 
                columns: [:id], # joining key for the association
                model: OtherModel 
              }
            }
          }
        end
        it_behaves_like 'a proper selector'
      end
      context 'aliased associations without recursion (that map to columns and other associations)' do
        let(:fields) { {aliased_method: true} }
        let(:selectors) do
          {
            model: SimpleModel,
            columns: [:column1, :other_model_id], # other_model_id => because of the association
            tracks: {
              other_model: { 
                columns: [:id], # joining key for the association
                model: OtherModel 
              }
            }
          }
        end
        it_behaves_like 'a proper selector'
      end

      context 'redefined associations that add some extra columns (would need both the underlying association AND the columns in place)' do
        let(:fields) { {parent: true} }
        let(:selectors) do
          {
            model: SimpleModel,
            columns: [:parent_id, :added_column],
            tracks: {
              parent: { 
                columns: [:id],
                model: ParentModel
              }
            }
          }
        end
        it_behaves_like 'a proper selector'
      end

      context 'a simple property that requires all fields' do
        let(:fields) { {everything: true} }
        let(:selectors) do
          {
            model: SimpleModel,
            columns: [:*],
          }
        end
        it_behaves_like 'a proper selector'
      end

      context 'a simple property that requires itself' do
        let(:fields) { {circular_dep: true} }
        let(:selectors) do
          {
            model: SimpleModel,
            columns: [:circular_dep, :column1], #allows to "expand" the dependency into itself + others
          }
        end
        it_behaves_like 'a proper selector'
      end

      context 'a simple property without dependencies' do
        let(:fields) { {no_deps: true} }
        let(:selectors) do
          {
            model: SimpleModel
          }
        end
        it_behaves_like 'a proper selector'
      end

    end

    context 'nested tracking' do
      context 'pure associations follow the nested fields' do
        let(:fields) do
          { 
            other_model: {
              id: true
            }
          }
        end
        let(:selectors) do
          {
            model: SimpleModel,
            columns: [:other_model_id],
            tracks: {
              other_model: {
                model: OtherModel,
                columns: [:id]
              }
            }
          }
        end
        it_behaves_like 'a proper selector'
      end

      context 'Aliased resources disregard any nested fields...' do
        let(:fields) do
          {
            other_resource: {
              id: true
            }
          }
        end
        let(:selectors) do
          {
            model: SimpleModel,
            columns: [:other_model_id],
            tracks: {
              other_model: {
                model: OtherModel,
                columns: [:id]
              }
            }
          }
        end
        it_behaves_like 'a proper selector'
      end

      context 'merging multiple tracks with the same name within a node' do
        let(:fields) do
          { # Both everything_from_parent and parent will track the underlying 'parent' assoc
            # ...and the final respective fields and tracks will need to be merged together.
            # columns will be merged by just *, and tracks will merge true with simple children
            everything_from_parent: true,
            parent: {
              simple_children: true
            }
          }
        end
        let(:selectors) do
          {
            model: SimpleModel,
            columns: [:parent_id, :added_column],
            tracks: {
              parent: {
                model: ParentModel,
                columns: [:*],
                tracks: {
                  simple_children: {
                    model: SimpleModel,
                    columns: [:parent_id]
                  }
                }
              }
            }
          }
        end
        it_behaves_like 'a proper selector'
      end
    end

    context 'string associations' do
      context 'that specify a direct existing colum in the target dependency' do
        let(:fields) { { direct_other_name: true } }
        let(:selectors) do
          {
            model: SimpleModel,
            columns: [:other_model_id],
            tracks: {
              other_model: {
                model: OtherModel,
                columns: [:id, :name]
              }
            }
          }
        end
        it_behaves_like 'a proper selector'
      end

      context 'that specify an aliased property in the target dependency' do
        let(:fields) { { aliased_other_name: true } }
        let(:selectors) do
          {
            model: SimpleModel,
            columns: [:other_model_id],
            tracks: {
              other_model: {
                model: OtherModel,
                columns: [:id, :name]
              }
            }
          }
        end
        it_behaves_like 'a proper selector'
      end

      context 'for a property that requires all fields from an association' do
        let(:fields) { {everything_from_parent: true} }
        let(:selectors) do
          {
            model: SimpleModel,
            columns: [:parent_id],
            tracks: {
              parent: { 
                model: ParentModel,
                columns: [:*]
              }
            }
          }
        end
        it_behaves_like 'a proper selector'
      end
    end

    context 'required extra select fields due to associations' do
      context 'many_to_one' do
        let(:fields) { {other_model: true} }
        let(:selectors) do
          {
            model: SimpleModel,
            columns: [:other_model_id], # FK of the other_model association
            tracks: {
              other_model: { 
                columns: [:id],
                model: OtherModel 
              }
            }
          }
        end
        it_behaves_like 'a proper selector'
      end
      context 'one_to_many' do
        let(:resource) { ParentResource }
        let(:fields) { {simple_children: true} }
        let(:selectors) do
          {
            model: ParentModel,
            columns: [:id], # No FKs in the source model for one_to_many
            tracks: {
              simple_children: { 
                columns: [:parent_id],
                model: SimpleModel 
              }
            }
          }
        end
        it_behaves_like 'a proper selector'
      end      
      context 'many_to_many' do
        let(:resource) { OtherResource }
        let(:fields) { {simple_models: true} }
        let(:selectors) do
          {
            model: OtherModel,
            columns: [:id], #join key in the source model for many_to_many (where the middle table points to)
            tracks: {
              simple_models: { 
                columns: [:id], #join key in the target model for many_to_many (where the middle table points to)
                model: SimpleModel
              }
            }
          }
        end
        it_behaves_like 'a proper selector'
      end      

    end
  end
end
