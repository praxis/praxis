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
      context 'terminal fields' do
        context 'with no dependencies' do
          context 'using a column name' do
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
                  fields: {
                    simple_name: {
                      deps:%i[simple_name]
                    }
                  }
                }
              }
            end
            it_behaves_like 'a proper selector'
          end
          context 'using an association name' do
            let(:fields) do
              {
                other_model: true
              }
            end
            let(:selectors) do
              {
                model: SimpleModel,
                columns: %i[other_model_id],
                field_deps: {
                  fields: {
                    other_model: {
                      references: 'Linked to resource: OtherResource'
                    }
                  }
                },
                tracks: {
                  other_model: {
                    model: OtherModel,
                    field_deps: {
                      fields: {
                        id: { deps: %i[id] }
                      }
                    },
                    columns: %i[id]
                  }
                }
              }
            end
            it_behaves_like 'a proper selector'
          end

          context 'using a forwarding association name with 1 level deep' do
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
                  fields: {
                    aliased_association: {
                      deps: [:aliased_association],
                      references: 'Linked to resource: OtherResource'
                    }
                  }
                },
                tracks: {
                  other_model: {
                    model: OtherModel,
                    field_deps: {
                      fields: {
                        id: {
                          deps: %i[id]
                        }
                    }
                    },
                    columns: %i[id]
                  }
                }
              }
            end
            it_behaves_like 'a proper selector'
          end
          context 'using a forwarding association name with 2 levels deep' do
            let(:fields) do
              {
                deep_overriden_aliased_association: true
              }
            end
            let(:selectors) do
              {
                model: SimpleModel,
                columns: %i[parent_id],
                field_deps: {
                  fields: {
                    deep_overriden_aliased_association: {
                      deps: [:deep_overriden_aliased_association],
                      references: 'Linked to resource: SimpleResource'
                    }
                  }
                },
                tracks: {
                  parent: {
                    model: ParentModel,
                    columns: %i[id],
                    field_deps: {
                      fields: {
                        aliased_simple_children: {
                          deps: [:aliased_simple_children],
                          references: 'Linked to resource: SimpleResource'
                        },
                        id: {
                          deps: %i[id]
                        }
                      }
                    },
                    tracks: {
                      simple_children: {
                        model: SimpleModel,
                        columns: %i[parent_id],
                        field_deps: {
                          fields: {
                            parent_id: {
                              deps: %i[parent_id]
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
        context 'with dependencies using TRUE' do
          context 'that have recursive properties' do
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
                  fields: {
                    name: {
                      deps:%i[simple_name nested_name name]
                    }
                  }
                }
              }
            end
            it_behaves_like 'a proper selector'
          end

          pending 'which include properties and associacions' do
            # How do we represent aliased_method if it has a combo of columns and associations? ...
            let(:fields) do
              {
                aliased_method: true
              }
            end
            let(:selectors) do
              {
                model: SimpleModel,
                columns: %i[column1],
                field_deps: {
                  fields: {
                    aliased_method: {
                      deps: %i[column1]
                    }
                  }
                },
                tracks: {
                  other_model: {
                    model: OtherModel,
                    columns: %i[id],
                    field_deps: {
                      fields: {
                        id: { deps: %i[id]
                        }
                      }
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
                  fields: {
                    everything: {
                      deps: %i[everything]
                    }
                  }
                }
              }
            end
            it_behaves_like 'a proper selector'
          end

          context 'self referential' do
            let(:fields) do
              {
                circular_dep: true
              }
            end
            let(:selectors) do
              {
                model: SimpleModel,
                columns: %i[circular_dep column1],
                field_deps: {
                  fields: {
                    circular_dep: {
                      deps:%i[circular_dep column1]
                    }
                  }
                }
              }
            end
            it_behaves_like 'a proper selector'
          end

          context 'with empty array dependencies' do
            let(:fields) { { no_deps: true } }
            let(:selectors) do
              {
                model: SimpleModel,
                field_deps: {
                  fields: {
                    no_deps: {
                      deps: %i[no_deps]
                    }
                  }
                }
              }
            end
            it_behaves_like 'a proper selector'
          end

          context 'a true substructure object' do
            # once we hit true_struct, we know it is not a property group, so we'll bring ALL the inner dependencies
            # even if the fields required are only a subset of it
            let(:fields) do
              {
                true_struct: true
              }
            end
            let(:selectors) do
              {
                model: SimpleModel,
                columns: %i[simple_name id],
                field_deps: {
                  fields: {
                    true_struct: {
                      deps: %i[true_struct name nested_name simple_name sub_id sub_sub_id id]
                    }
                  }
                }
              }
            end
            it_behaves_like 'a proper selector'
          end
        end

        context 'with dependencies using subfields' do
          context 'a true substructure object' do
            # once we hit true_struct, we know it is not a property group, so we'll bring ALL the inner dependencies
            # even if the fields required are only a subset of it
            let(:fields) do
              {
                true_struct: {
                  sub_id: {
                    sub_sub_id: true
                  }
                }
              }
            end
            let(:selectors) do
              {
                model: SimpleModel,
                columns: %i[simple_name id],
                field_deps: {
                  fields: {
                    true_struct: {
                      deps: %i[true_struct name nested_name simple_name sub_id sub_sub_id id]
                    }
                  }
                }
              }
            end
            it_behaves_like 'a proper selector'
          end

          context 'a true substructure object with property names prefixed like a property group (is still treated as a struct loading it all)' do
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
                columns: %i[id simple_name], # No name of any sort processed here, despite :name being a dep for agroup
                field_deps: {
                  fields: {
                    agroup: {
                      deps: %i[agroup agroup_id id agroup_name name nested_name simple_name]
                    }
                  }
                }
              }
            end
            it_behaves_like 'a proper selector'
          end
        end

        context 'property groups' do
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
                  fields: {
                    grouped: {
                      deps: %i[grouped],
                      fields: {
                        name: {
                          deps: %i[grouped_name name nested_name simple_name]
                        }
                      }
                      # NO id or group_id or tags of any sort should be traversed and appear, as we didn't ask for them
                    }
                  }
                }
              }
            end
            it_behaves_like 'a proper selector'
          end

          context 'a property group substructure object, but asking only a subset of fields, going deep in an association' do
            let(:resource) { Resources::Book }
            let(:fields) do
              {
                grouped: {
                  id: true,
                  #name: true,
                  moar_tags: {
                    # name: true,
                    label: true
                  }
                }
              }
            end
            let(:selectors) do
              {
                model: ::ActiveBook,
                # No tags or tag tracking, despite the grouped prop has that dependency (but we didn't ask for it)
                columns: %i[id],
                field_deps: {
                  fields: {
                    grouped: {
                      deps: %i[grouped],
                      fields: {
                        id: {
                          deps: %i[grouped_id id]
                        },
                        moar_tags: {
                          deps: %i[grouped_moar_tags],
                          references: 'Linked to resource: Resources::Tag'
                        }
                      }
                      # NO name of any other name related things
                    }
                  }
                },
                tracks: {
                  tags: {
                    model: ActiveTag,
                    columns: %i[id label],
                    field_deps: {
                      fields: {
                        id: {
                          deps: %i[id]
                        },
                        label: {
                          deps: %i[label]
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
  #     context 'single direct dependency that it association' do
  #       # "field_deps": {
  #       #   "other_model": {
  #       #     "true": {
  #       #       "local_deps": [],
  #       #       "target_selgen": "#<Praxis::Mapper::SelectorGeneratorNode:0x00007fe6fb332ef0>"
  #       #     }
  #       #   }
  #       # },
  #       let(:fields) do
  #         {
  #           other_model: true
  #         }
  #       end
  #       it_behaves_like 'a proper selector'
  #     end

  #     context 'TESTING single direct association with a direct subfield' do
  #       # "field_deps": {
  #       #   {
  #       #     "other_model": {
  #       #       "true": {
  #       #         "local_deps": [],
  #       #         "target_selgen": "#<Praxis::Mapper::SelectorGeneratorNode:0x00007f7b4886ce80>"
  #       #       },
  #       #       "name": {
  #       #         "true": {
  #       #           "local_deps": [],
  #       #           "target_selgen": "#<Praxis::Mapper::SelectorGeneratorNode:0x00007f7b4886ce80>"
  #       #         }
  #       #       }
  #       #     }
  #       #   }
  #       # }
  #       let(:fields) do
  #         {
  #           other_model: {
  #             name: true
  #           }
  #         }
  #       end
  #       it_behaves_like 'a proper selector'
  #     end

  #     context 'TESTING single aliased association' do
  #       # "field_deps": {
  #       #   "other_model": {
  #       #     "true": {
  #       #       "local_deps": [],
  #       #       "target_selgen": "#<Praxis::Mapper::SelectorGeneratorNode:0x00007fe6fb332ef0>"
  #       #     }
  #       #   }
  #       # },
  #       let(:fields) do
  #         {
  #           other_resource: true
  #         }
  #       end
  #       it_behaves_like 'a proper selector'
  #     end

  #     context 'TESTING single aliased association with an aliased subfield' do
  #       # "field_deps": {
  #       #   {
  #       #     "other_model": {
  #       #       "true": {
  #       #         "local_deps": [],
  #       #         "target_selgen": "#<Praxis::Mapper::SelectorGeneratorNode:0x00007f7b4886ce80>"
  #       #       },
  #       #       "display_name": {
  #       #         "true": {
  #       #           "local_deps": [name],
  #       #           "target_selgen": "#<Praxis::Mapper::SelectorGeneratorNode:0x00007f7b4886ce80>"
  #       #         }
  #       #       }
  #       #     }
  #       #   }
  #       # }
  #       let(:fields) do
  #         {
  #           other_resource: {
  #             display_name: true
  #           }
  #         }
  #       end
  #       it_behaves_like 'a proper selector'
  #     end

  #     context 'TESTING single property field multiple with deps' do
  #       let(:fields) do
  #         {
  #           multi_column: true
  #         }
  #       end
  #       let(:selectors) do
  #         {
  #           model: SimpleModel,
  #           columns: %i[column1 simple_name],
  #           field_deps: {
  #             multi_column: %i[multi_column column1 simple_name]
  #           }
  #         }
  #       end
  #       it_behaves_like 'a proper selector'
  #     end

  #     context 'TESTING single aliased property which is not an association' do
  #       let(:fields) do
  #         {
  #           name: true
  #         }
  #       end
  #       let(:selectors) do
  #         {
  #           model: SimpleModel,
  #           columns: %i[simple_name],
  #           field_deps: {
  #             name: %i[name nested_name simple_name]
  #           }
  #         }
  #       end
  #       it_behaves_like 'a proper selector'
  #     end

  #     context 'TESTING single aliased property with fields TRUE that points to an association (but not an :as)' do
  #       let(:fields) do
  #         {
  #           other_resource: true
  #         }
  #       end
  #       let(:selectors) do
  #         {
  #           model: SimpleModel,
  #           columns: %i[other_model_id],
  #           field_deps: {
  #             other_resource: %i[other_resource other_model]
  #           },
  #           tracks: {
  #             other_model: {
  #               model: OtherModel,
  #               field_deps: {
  #                 id: %i[id]
  #               },
  #               columns: %i[id]
  #             }
  #           }
  #         }
  #       end
  #       it_behaves_like 'a proper selector'
  #     end

  #     context 'TESTING single aliased property with subfields that points to an association (but not an :as)' do
  #       let(:fields) do
  #         {
  #           other_resource: {
  #             # Subfields will be disregarded, as it is not an :as association, so we don't know what the implementing method will return
  #             # This means that other model will not attempt to track simple_name or any dependency based on that
  #             display_name: true
  #           }
  #         }
  #       end
  #       let(:selectors) do
  #         {
  #           model: SimpleModel,
  #           columns: %i[other_model_id],
  #           field_deps: {
  #             other_resource: %i[other_resource other_model]
  #           },
  #           tracks: {
  #             other_model: {
  #               model: OtherModel,
  #               field_deps: {
  #                 id: %i[id]
  #               },
  #               columns: %i[id]
  #             }
  #           }
  #         }
  #       end
  #       it_behaves_like 'a proper selector'
  #     end

  #     context 'TESTING single aliased property with TRUE defined as an :as association' do
  #       let(:fields) do
  #         {
  #           aliased_association: true
  #         }
  #       end
  #       let(:selectors) do
  #         {
  #           model: SimpleModel,
  #           columns: %i[other_model_id],
  #           field_deps: {
  #             aliased_association: { # A HASH!!!
  #               forwarded: [
  #                 :other_model
  #               ]
  #             }
  #           },
  #           tracks: {
  #             other_model: {
  #               model: OtherModel,
  #               field_deps: {
  #                 id: %i[id]
  #               },
  #               columns: %i[id]
  #             }
  #           }
  #         }
  #       end
  #       it_behaves_like 'a proper selector'
  #     end

  #     context 'TESTING two levels aliased property with TRUE defined as an :as association' do
  #       let(:fields) do
  #         {
  #           deep_aliased_association: true
  #         }
  #       end
  #       let(:selectors) do
  #         {
  #           model: SimpleModel,
  #           columns: %i[other_model_id],
  #           field_deps: {
  #             deep_aliased_association: { # A HASH!!!
  #               forwarded: [
  #                 :parent, :simple_children
  #               ]
  #             }
  #           },
  #           tracks: {
  #             parent: {
  #               model: ParentModel,
  #               field_deps: {
  #                 # These two deps would be nice not to be here...(maybe we can simply ignore them if they aren't in the incoming fields...)
  #                 simple_children: %i[simple_children], 
  #                 id: %i[id]
  #               },
  #               columns: %i[id],
  #               tracks: {
  #                 simple_children: {
  #                   model: SimpleModel,
  #                   field_deps: {
  #                     parent_id: %i[parent_id]
  #                   },
  #                   columns: %i[parent_id],
  #                 }
  #               }
  #             }
  #           }
  #         }
  #       end
  #       it_behaves_like 'a proper selector'
  #     end
  #   end
  end
end