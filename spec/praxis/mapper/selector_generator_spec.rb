# frozen_string_literal: true

require 'spec_helper'

describe Praxis::Mapper::SelectorGenerator do
  let(:resource) { SimpleResource }
  subject(:generator) { described_class.new }

  context '#add' do
    let(:resource) { SimpleResource }
    shared_examples 'a proper selector' do
      it { 
        dumped = generator.add(resource, fields).selectors.dump
        puts JSON.pretty_generate(dumped)
        expect(dumped).to be_deep_equal selectors
      }
    end

    context 'basic combos' do
      context 'direct column fields' do
        let(:fields) { { id: true, foobar: true } }
        let(:selectors) do
          {
            model: SimpleModel,
            columns: %i[id foobar],
            field_deps: {
              id: %i[id],
              foobar: %i[foobar]
            }
          }
        end
        it_behaves_like 'a proper selector'
      end

      context 'aliased column fields' do
        let(:fields) { { id: true, name: true } }
        let(:selectors) do
          {
            model: SimpleModel,
            columns: %i[id simple_name],
            field_deps: {
              id: %i[id],
              name: %i[name nested_name simple_name]
            }
          }
        end
        it_behaves_like 'a proper selector'
      end

      context 'pure associations without recursion' do
        let(:fields) { { other_model: true } }
        let(:selectors) do
          {
            model: SimpleModel,
            columns: [:other_model_id], # FK of the other_model association
            field_deps: {
              other_model: %i[other_model_id]
            },
            tracks: {
              other_model: {
                columns: [:id], # joining key for the association
                model: OtherModel,
                field_deps: {
                  id: %i[id]
                }
              }
            }
          }
        end
        it_behaves_like 'a proper selector'
      end

      context 'aliased associations without recursion' do
        let(:fields) { { other_resource: true } }
        let(:selectors) do
          {
            model: SimpleModel,
            columns: [:other_model_id], # FK of the other_model association
            field_deps: {
              other_resource:%i[other_resource other_model_id]
            },
            tracks: {
              other_model: {
                columns: [:id], # joining key for the association
                model: OtherModel,
                field_deps: {
                  id: %i[id]
                }
              }
            }
          }
        end
        it_behaves_like 'a proper selector'
      end
      context 'aliased associations without recursion (that map to columns and other associations)' do
        let(:fields) { { aliased_method: true } }
        let(:selectors) do
          {
            model: SimpleModel,
            columns: %i[column1 other_model_id], # other_model_id => because of the association
            field_deps: {
              aliased_method: %i[aliased_method column1 other_model_id]
            },
            tracks: {
              other_model: {
                columns: [:id], # joining key for the association 
                model: OtherModel,
                field_deps: {
                  id: %i[id]
                }
              }
            }
          }
        end
        it_behaves_like 'a proper selector'
      end

      context 'redefined associations that add some extra columns (would need both the underlying association AND the columns in place)' do
        let(:fields) { { parent: true } }
        let(:selectors) do
          {
            model: SimpleModel,
            columns: %i[parent_id added_column],
            field_deps: {
              parent: %i[parent parent_id added_column]
            },
            tracks: {
              parent: {
                columns: [:id],
                model: ParentModel,
                field_deps: {
                  id: %i[id]
                }
              }
            }
          }
        end
        it_behaves_like 'a proper selector'
      end

      context 'a simple property that requires all fields' do
        let(:fields) { { everything: true } }
        let(:selectors) do
          {
            model: SimpleModel,
            columns: [:*],
            field_deps: {
              everything: %i[everything]
            }
          }
        end
        it_behaves_like 'a proper selector'
      end

      context 'a simple property that requires itself' do
        let(:fields) { { circular_dep: true } }
        let(:selectors) do
          {
            model: SimpleModel,
            columns: %i[circular_dep column1], # allows to "expand" the dependency into itself + others
            field_deps: {
              circular_dep: %i[circular_dep column1]
            }
          }
        end
        it_behaves_like 'a proper selector'
      end

      context 'a simple property without dependencies' do
        let(:fields) { { no_deps: true } }
        let(:selectors) do
          {
            model: SimpleModel,
            field_deps: {
              no_deps: %i[no_deps]
            }
          }
        end
        it_behaves_like 'a proper selector'
      end

      context 'a true substructure object' do
        # This assumes that the properties are properly prefixed from the struct
        # For nicer naming, use a property group where these prefixed properties will be
        # done automatically AND the generator will try to find them as such
        # NOTE: We could probably try to do that for real structs as well...not necessarily groups
        let(:fields) do
          {
            true_struct: {
              name: true,
              sub_id: {
                sub_sub_id: true
              }
            }
          }
        end
        let(:selectors) do
          {
            model: SimpleModel,
            # Parent_id is because we asked for it at the top
            # display_name because we asked for it under sub_struct, but it is marked as :self
            # alway_necessary_attribute because it is a dependency of sub_struct
            columns: %i[simple_name id],
            field_deps: {
              true_struct: {
                name: %i[name nested_name simple_name],
                sub_id: {
                  sub_sub_id: %i[sub_sub_id id]
                }
              }
            }
          }
        end
        it_behaves_like 'a proper selector'
      end

      context 'a true substructure object without prefixing' do
        let(:fields) do
          {
            agroup: {
              id: true
            }
          }
        end
        let(:selectors) do
          {
            model: SimpleModel,
            columns: %i[id], # No name of any sort processed here, despite :name being a dep for agroup
            field_deps: {
              agroup: {
                id: %i[agroup_id id]
              }
            }
          }
        end
        it_behaves_like 'a proper selector'
      end

      context 'a property group substructure object, but asking only 1 of the subfields' do
        let(:resource) { Resources::Book }
        let(:fields) do
          {
            grouped: {
              # id: true,
              name: true,
              # moar_tags
            }
          }
        end
        let(:selectors) do
          {
            model: ::ActiveBook,
            # No tags or tag tracking, despite the grouped prop has that dependency (but we didn't ask for it)
            columns: %i[simple_name], 
            field_deps: {
              grouped: {
                name: %i[name grouped_name nested_name simple_name]
                # NO id or group_id or tags of any sort should be traversed and appear, as we didn't ask for them
              }
            }
          }
        end
        it_behaves_like 'a proper selector'
      end
      context 'a property group substructure object, but asking only a subset of fields (including an association)' do
        let(:resource) { Resources::Book }
        let(:fields) do
          {
            grouped: {
              id: true,
              #name: true,
              moar_tags: true
            }
          }
        end
        let(:selectors) do
          {
            model: ::ActiveBook,
            # No tags or tag tracking, despite the grouped prop has that dependency (but we didn't ask for it)
            columns: %i[id],
            field_deps: {
              grouped: {
                id: %i[grouped_id id],
                moar_tags: %i[grouped_moar_tags id]
              }
            },
            tracks: {
              tags: {
                model: ActiveTag,
                columns: [:id],
                field_deps: {
                  id: %i[id]
                }
              }
            }
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
            field_deps: {
              other_model: %i[other_model_id]
            },
            tracks: {
              other_model: {
                model: OtherModel,
                columns: [:id],
                field_deps: {
                  id: %i[id]
                }
              }
            }
          }
        end
        it_behaves_like 'a proper selector'
      end

      context 'Aliased resources disregard any nested fields...if they do not match a prefixed prop' do
        let(:fields) do
          {
            other_resource: {
              display_name: true # Does not match any prop with 'other_resource_display_name' So no deps processed!
            }
          }
        end
        let(:selectors) do
          {
            model: SimpleModel,
            field_deps: {
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
            # columns: %i[parent_id added_column], #TODO: added_column is discarded when there's childen...is that right if it's an inner relationship? Perhaps...
            columns: %i[parent_id],
            field_deps: {
              everything_from_parent: %i[everything_from_parent parent_id],
              # parent: %i[parent parent_id]
              parent: %i[parent_id]
            },
            tracks: {
              parent: {
                model: ParentModel,
                columns: [:*],
                field_deps: { # TODO: empty field deps is a bit odd
                },
                tracks: {
                  simple_children: {
                    model: SimpleModel,
                    columns: [:parent_id],
                    field_deps: { # TODO: parent_id isn't a field, so while true it is a bit odd to see here
                      parent_id: [:parent_id]
                    }
                  }
                }
              }
            }
          }
        end
        it_behaves_like 'a proper selector'
      end
      context 'Aliased underlying associations follows any nested fields...' do
        let(:fields) do
          {
            parent_id: true,
            aliased_association: {
              display_name: true
            }
          }
        end
        let(:selectors) do
          {
            model: SimpleModel,
            # columns: %i[other_model_id parent_id simple_name], NO, display_name is only processed in the aliased association!
            columns: %i[other_model_id parent_id],
            field_deps: {
              parent_id: %i[parent_id],
              # aliased_association: %i[aliased_association other_model_id name nested_name simple_name] NO! it is an association!
              # TODO: the aliased association...should be here? or not?...good question
              aliased_association: %i[other_model_id]
            },
            tracks: {
              other_model: {
                model: OtherModel,
                columns: %i[id name],
                field_deps: {
                  id: %i[id],
                  display_name: %i[display_name name]
                }
              }
            }
          }
        end
        it_behaves_like 'a proper selector'
      end
      context 'Deep aliased underlying associations also follows any nested fields at the end of the chain...' do
        let(:fields) do
          {
            parent_id: true,
            deep_aliased_association: {
              name: true
            }
          }
        end
        let(:selectors) do
          {
            model: SimpleModel,
            columns: %i[parent_id],
            field_deps: {
              parent_id: %i[parent_id],
              deep_aliased_association: %i[parent_id]
            },
            tracks: {
              parent: {
                model: ParentModel,
                columns: %i[id],
                field_deps: {
                  simple_children: %i[id],
                  id: %i[id]
                },
                tracks: {
                  simple_children: {
                    model: SimpleModel,
                    columns: %i[parent_id simple_name],
                    field_deps: {
                      parent_id: %i[parent_id],
                      name: %i[name nested_name simple_name]
                    }
                  }
                }
              }
            }
          }
        end
        it_behaves_like 'a proper selector'
      end
      context 'Using self for the underlying association: follows any nested fields skipping the association name and still applies dependencies' do
        let(:fields) do
          {
            parent_id: true,
            sub_struct: {
              name: true
            }
          }
        end
        let(:selectors) do
          {
            model: SimpleModel,
            # Parent_id is because we asked for it at the top
            # simple_name because we asked for it under sub_struct, but it is marked as :self
            columns: %i[parent_id simple_name],
            field_deps: {
              parent_id: %i[parent_id],
              sub_struct: {
                name: %i[name nested_name simple_name]
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
            field_deps: {
              direct_other_name: %i[direct_other_name other_model_id]
            },
            tracks: {
              other_model: {
                model: OtherModel,
                columns: %i[id name],
                field_deps: {
                  id: %i[id],
                  name: %i[name]
                }
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
            field_deps: {
              aliased_other_name: %i[aliased_other_name other_model_id]
            },
            tracks: {
              other_model: {
                model: OtherModel,
                columns: %i[id name],
                field_deps: {
                  id: %i[id],
                  display_name: %i[display_name name]
                }
              }
            }
          }
        end
        it_behaves_like 'a proper selector'
      end

      context 'for a property that requires all fields from an association' do
        let(:fields) { { everything_from_parent: true } }
        let(:selectors) do
          {
            model: SimpleModel,
            columns: [:parent_id],
            field_deps: {
              everything_from_parent: %i[everything_from_parent parent_id]
            },
            tracks: {
              parent: {
                model: ParentModel,
                columns: [:*],
                field_deps: {
                }
              }
            }
          }
        end
        it_behaves_like 'a proper selector'
      end
    end

    context 'required extra select fields due to associations' do
      context 'many_to_one' do
        let(:fields) { { other_model: true } }
        let(:selectors) do
          {
            model: SimpleModel,
            columns: [:other_model_id], # FK of the other_model association
            field_deps: {
              other_model: %i[other_model_id]
            },
            tracks: {
              other_model: {
                columns: [:id],
                model: OtherModel,
                field_deps: {
                  id: %i[id]
                }
              }
            }
          }
        end
        it_behaves_like 'a proper selector'
      end
      context 'one_to_many' do
        let(:resource) { ParentResource }
        let(:fields) { { simple_children: true } }
        let(:selectors) do
          {
            model: ParentModel,
            columns: [:id], # No FKs in the source model for one_to_many
            field_deps: {
              simple_children: %i[id]
            },
            tracks: {
              simple_children: {
                columns: [:parent_id],
                model: SimpleModel,
                field_deps: {
                  parent_id: %i[parent_id]
                },
              }
            }
          }
        end
        it_behaves_like 'a proper selector'
      end
      context 'many_to_many' do
        let(:resource) { OtherResource }
        let(:fields) { { simple_models: true } }
        let(:selectors) do
          {
            model: OtherModel,
            columns: [:id], # join key in the source model for many_to_many (where the middle table points to)
            field_deps: {
              simple_models: %i[id]
            },
            tracks: {
              simple_models: {
                columns: [:id], # join key in the target model for many_to_many (where the middle table points to)
                model: SimpleModel,
                field_deps: {
                  id: %i[id]
                },
              }
            }
          }
        end
        it_behaves_like 'a proper selector'
      end

      context 'that are several attriutes deep' do
        let(:fields) { { deep_nested_deps: true } }
        let(:selectors) do
          {
            model: SimpleModel,
            columns: [:parent_id],
            field_deps: {
              deep_nested_deps: %i[deep_nested_deps parent_id]
            },
            tracks: {
              parent: {
                model: ParentModel,
                columns: [:id], # No FKs in the source model for one_to_many
                field_deps: {
                  id: %i[id],
                  simple_children: %i[id]
                },
                tracks: {
                  simple_children: {
                    columns: %i[parent_id other_model_id],
                    model: SimpleModel,
                    field_deps: {
                      other_model: %i[other_model_id],
                      parent_id: %i[parent_id]
                    },
                    tracks: {
                      other_model: {
                        model: OtherModel,
                        columns: %i[id parent_id],
                        field_deps: {
                          id: %i[id],
                          parent: %i[parent_id]
                        },
                        tracks: {
                          parent: {
                            model: ParentModel,
                            columns: %i[id simple_name other_attribute],
                            field_deps: {
                              id: %i[id],
                              display_name: %i[display_name simple_name id other_attribute]
                            }
                          }
                        }
                      }
                    }
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
