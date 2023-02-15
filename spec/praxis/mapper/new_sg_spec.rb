# frozen_string_literal: true

require 'spec_helper'

describe Praxis::Mapper::SelectorGenerator do
  let(:resource) { SimpleResource }
  subject(:generator) { described_class.new }

  context '#add' do
    let(:resource) { SimpleResource }
    shared_examples 'a proper selector' do
      it do
        dumped = generator.add(resource, fields).selectors.dump
        puts JSON.pretty_generate(dumped)
        expect(dumped).to be_deep_equal selectors
      end
    end

    context 'NEW TESTING', focus: true do
      context 'a single direct field' do
        let(:fields) do
          {
            simple_name: true
          }
        end
        let(:selectors) do
          {
            model: SimpleModel,
            columns: %i[simple_name],
            field_deps: {
              simple_name: %i[simple_name]
            }
          }
        end
        it_behaves_like 'a proper selector'
      end

      context 'TESTING single direct association' do
        # "field_deps": {
        #   "other_model": {
        #     "true": {
        #       "local_deps": [],
        #       "target_selgen": "#<Praxis::Mapper::SelectorGeneratorNode:0x00007fe6fb332ef0>"
        #     }
        #   }
        # },
        let(:fields) do
          {
            other_model: true
          }
        end
        it_behaves_like 'a proper selector'
      end

      context 'TESTING single direct association with a direct subfield' do
        # "field_deps": {
        #   {
        #     "other_model": {
        #       "true": {
        #         "local_deps": [],
        #         "target_selgen": "#<Praxis::Mapper::SelectorGeneratorNode:0x00007f7b4886ce80>"
        #       },
        #       "name": {
        #         "true": {
        #           "local_deps": [],
        #           "target_selgen": "#<Praxis::Mapper::SelectorGeneratorNode:0x00007f7b4886ce80>"
        #         }
        #       }
        #     }
        #   }
        # }
        let(:fields) do
          {
            other_model: {
              name: true
            }
          }
        end
        it_behaves_like 'a proper selector'
      end

      context 'TESTING single aliased association' do
        # "field_deps": {
        #   "other_model": {
        #     "true": {
        #       "local_deps": [],
        #       "target_selgen": "#<Praxis::Mapper::SelectorGeneratorNode:0x00007fe6fb332ef0>"
        #     }
        #   }
        # },
        let(:fields) do
          {
            other_resource: true
          }
        end
        it_behaves_like 'a proper selector'
      end

      context 'TESTING single aliased association with an aliased subfield' do
        # "field_deps": {
        #   {
        #     "other_model": {
        #       "true": {
        #         "local_deps": [],
        #         "target_selgen": "#<Praxis::Mapper::SelectorGeneratorNode:0x00007f7b4886ce80>"
        #       },
        #       "display_name": {
        #         "true": {
        #           "local_deps": [name],
        #           "target_selgen": "#<Praxis::Mapper::SelectorGeneratorNode:0x00007f7b4886ce80>"
        #         }
        #       }
        #     }
        #   }
        # }
        let(:fields) do
          {
            other_resource: {
              display_name: true
            }
          }
        end
        it_behaves_like 'a proper selector'
      end

      context 'TESTING single property field multiple with deps' do
        let(:fields) do
          {
            multi_column: true
          }
        end
        let(:selectors) do
          {
            model: SimpleModel,
            columns: %i[column1 simple_name],
            field_deps: {
              multi_column: %i[multi_column column1 simple_name]
            }
          }
        end
        it_behaves_like 'a proper selector'
      end

      context 'TESTING single aliased property which is not an association' do
        let(:fields) do
          {
            name: true
          }
        end
        let(:selectors) do
          {
            model: SimpleModel,
            columns: %i[simple_name],
            field_deps: {
              name: %i[name nested_name simple_name]
            }
          }
        end
        it_behaves_like 'a proper selector'
      end

      context 'TESTING single aliased property with fields TRUE that points to an association (but not an :as)' do
        let(:fields) do
          {
            other_resource: true
          }
        end
        let(:selectors) do
          {
            model: SimpleModel,
            columns: %i[other_model_id],
            field_deps: {
              other_resource: %i[other_resource other_model]
            },
            tracks: {
              other_model: {
                model: OtherModel,
                field_deps: {
                  id: %i[id]
                },
                columns: %i[id]
              }
            }
          }
        end
        it_behaves_like 'a proper selector'
      end

      context 'TESTING single aliased property with subfields that points to an association (but not an :as)' do
        let(:fields) do
          {
            other_resource: {
              # Subfields will be disregarded, as it is not an :as association, so we don't know what the implementing method will return
              # This means that other model will not attempt to track simple_name or any dependency based on that
              display_name: true
            }
          }
        end
        let(:selectors) do
          {
            model: SimpleModel,
            columns: %i[other_model_id],
            field_deps: {
              other_resource: %i[other_resource other_model]
            },
            tracks: {
              other_model: {
                model: OtherModel,
                field_deps: {
                  id: %i[id]
                },
                columns: %i[id]
              }
            }
          }
        end
        it_behaves_like 'a proper selector'
      end

      context 'TESTING single aliased property with TRUE defined as an :as association' do
        let(:fields) do
          {
            aliased_association: true
          }
        end
        let(:selectors) do
          {
            model: SimpleModel,
            columns: %i[other_model_id],
            field_deps: {
              aliased_association: { # A HASH!!!
                forwarded: [
                  :other_model
                ]
              }
            },
            tracks: {
              other_model: {
                model: OtherModel,
                field_deps: {
                  id: %i[id]
                },
                columns: %i[id]
              }
            }
          }
        end
        it_behaves_like 'a proper selector'
      end

      context 'TESTING two levels aliased property with TRUE defined as an :as association' do
        let(:fields) do
          {
            deep_aliased_association: true
          }
        end
        let(:selectors) do
          {
            model: SimpleModel,
            columns: %i[other_model_id],
            field_deps: {
              deep_aliased_association: { # A HASH!!!
                forwarded: [
                  :parent, :simple_children
                ]
              }
            },
            tracks: {
              parent: {
                model: ParentModel,
                field_deps: {
                  # These two deps would be nice not to be here...(maybe we can simply ignore them if they aren't in the incoming fields...)
                  simple_children: %i[simple_children], 
                  id: %i[id]
                },
                columns: %i[id],
                tracks: {
                  simple_children: {
                    model: SimpleModel,
                    field_deps: {
                      parent_id: %i[parent_id]
                    },
                    columns: %i[parent_id],
                  }
                }
              }
            }
          }
        end
        it_behaves_like 'a proper selector'
      end
    end
  end
end