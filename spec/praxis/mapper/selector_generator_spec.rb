# require 'spec_helper'

# describe Praxis::Mapper::SelectorGenerator do
#   let(:properties) { {} }
#   let(:resource) { BlogResource }
#   subject(:generator) {Praxis::Mapper::SelectorGenerator.new }

#   before do
#     generator.add(resource,properties)
#   end

#   let(:expected_selectors) { {} }

#   context 'for a simple field' do
#     let(:properties) { {id: true} }
#     let(:expected_selectors) do
#       {
#         BlogModel => {
#           select: Set.new([:id]),
#           track: Set.new()
#         }
#       }
#     end

#     it 'generates the correct set of selectors' do
#       generator.selectors.should eq expected_selectors
#     end
#   end

#   context 'for a simple property' do
#     let(:properties) { {display_name: true} }
#     let(:expected_selectors) do
#       {
#         BlogModel => {
#           select: Set.new([:name]),
#           track: Set.new()
#         }
#       }
#     end
#     it 'generates the correct set of selectors' do
#       generator.selectors.should eq expected_selectors
#     end
#   end

#   context 'for an association' do
#     let(:properties) { {owner: true} }
#     let(:expected_selectors) do
#       {
#         BlogModel => {
#           select: Set.new([:owner_id]),
#           track: Set.new([:owner])
#         }
#       }
#     end
#     it 'generates the correct set of selectors' do
#       generator.selectors.should eq expected_selectors
#     end

#     context 'that is many_to_many' do
#       let(:properties) { {commented_posts: true} }
#       let(:resource) { UserResource }
#       let(:expected_selectors) do
#         {
#           CommentModel => {
#             select: Set.new([:author_id, :post_id]),
#             track: Set.new([:post])
#           },
#           UserModel => {
#             select: Set.new([]),
#             track: Set.new([:comments])
#           }
#         }
#       end
#       it 'generates the correct set of selectors' do
#         generator.selectors.should eq expected_selectors
#       end
#     end

#     context 'that is many_to_many without a :through option' do
#       let(:properties) { {other_commented_posts: { id: true} } }
#       let(:resource) { UserResource }
#       let(:expected_selectors) do
#         {
#           PostModel => {
#             select: Set.new([:id]),
#             track: Set.new([])
#           },
#           UserModel => {
#             select: Set.new([]),
#             track: Set.new([:other_commented_posts])
#           }
#         }
#       end
#       it 'generates the correct set of selectors' do
#         generator.selectors.should eq expected_selectors
#       end
#     end


#     context 'that uses a composite key' do
#       let(:properties) { {composite_model: {id: true, type: true} } }
#       let(:resource) { OtherResource }
#       let(:expected_selectors) do
#         {
#           OtherModel => {
#             select: Set.new([:composite_id,:composite_type]),
#             track: Set.new([:composite_model])
#           },
#           CompositeIdModel => {
#             select: Set.new([:id,:type]),
#             track: Set.new
#           }
#         }
#       end
#       it 'generates the correct set of selectors' do
#         generator.selectors.should eq expected_selectors
#       end
#     end
#   end

#   context 'for a property that specifies a field from an association' do
#     let(:properties) { {owner_email: true} }
#     let(:expected_selectors) do
#       {
#         BlogModel => {
#           select: Set.new([:owner_id]),
#           track: Set.new([:owner])
#         },
#         UserModel => {
#           select: Set.new([:email]),
#           track: Set.new()
#         }
#       }
#     end

#     it 'generates the correct set of selectors' do
#       generator.selectors.should eq expected_selectors
#     end
#   end

#   context 'for a simple property that requires all fields' do
#     let(:properties) { {everything: true} }
#     let(:expected_selectors) do
#       {
#         BlogModel => {
#           select: true,
#           track: Set.new()
#         }
#       }
#     end
#     it 'generates the correct set of selectors' do
#       generator.selectors.should eq expected_selectors
#     end
#   end

#   context 'for property that uses an associated property' do
#     let(:properties) { {owner_full_name: true} }
#     let(:expected_selectors) do
#       {
#         BlogModel => {
#           select: Set.new([:owner_id]),
#           track: Set.new([:owner])
#         },
#         UserModel => {
#           select: Set.new([:first_name, :last_name]),
#           track: Set.new()
#         }
#       }
#     end
#     it 'generates the correct set of selectors' do
#       generator.selectors.should eq expected_selectors
#     end
#   end


#   context 'for a property that requires all fields from an association' do
#     let(:properties) { {everything_from_owner: true} }
#     let(:expected_selectors) do
#       {
#         BlogModel => {
#           select: Set.new([:owner_id]),
#           track: Set.new([:owner])
#         },
#         UserModel => {
#           select: true,
#           track: Set.new()
#         }
#       }
#     end
#     it 'generates the correct set of selectors' do
#       generator.selectors.should eq expected_selectors
#     end
#   end

#   context 'using a property that specifies a :through option' do
#     let(:properties) { {recent_posts: {author: {full_name: true}}} }
#     let(:resource) { UserResource }
#     let(:expected_selectors) do
#       {
#         PostModel => {
#           select: Set.new([:author_id, :created_at]),
#           track: Set.new([:author])
#         },
#         UserModel => {
#           select: Set.new([:first_name, :last_name]),
#           track: Set.new([:posts])
#         }
#       }
#     end
#     it 'generates the correct set of selectors' do
#       generator.selectors.should eq expected_selectors
#     end
#   end

#   context 'with a property with a circular definition (ie, includes its own field)' do
#     let(:resource) { PostResource }

#     let(:properties) { {id: true, slug: true} }
#     let(:expected_selectors) do
#       {
#         PostModel => {
#           select: Set.new([:id, :slug, :title]),
#           track: Set.new
#         }
#       }
#     end
#     it 'generates the correct set of selectors' do
#       generator.selectors.should eq expected_selectors
#     end
#   end

#   context 'with a property without the :through option' do
#     let(:resource) { UserResource }
#     let(:properties) { {blogs_summary: {size: true}} }
#     let(:expected_selectors) do
#      {
#        BlogModel => {
#          select: Set.new([:owner_id]),
#          track: Set.new()
#        },
#        UserModel => {
#          select: Set.new([:id]),
#          track: Set.new([:blogs])
#        }
#      }
#     end
#     it 'ignores any subsequent fields when generating selectors' do
#       generator.selectors.should eq expected_selectors
#     end
#   end

#   context 'for a property with no dependencies' do
#     let(:properties) { {id: true, kind: true} }
#     let(:expected_selectors) do
#       {
#         BlogModel => {
#           select: Set.new([:id]),
#           track: Set.new()
#         }
#       }
#     end
#     it 'generates the correct set of selectors' do
#       generator.selectors.should eq expected_selectors
#     end
#   end

#   context 'with large set of properties' do

#     let(:properties) do
#       {
#         display_name: true,
#         owner: {
#           id: true,
#           full_name: true,
#           blogs_summary: {href: true, size: true},
#           main_blog: {id: true},
#         },
#         administrator: {id: true, full_name: true}
#       }
#     end

#     let(:expected_selectors) do
#       {
#         BlogModel=> {
#           select: Set.new([:id, :name, :owner_id, :administrator_id]),
#           track: Set.new([:owner, :administrator])
#         },
#         UserModel=> {
#           select: Set.new([:id, :first_name, :last_name, :main_blog_id]),
#           track: Set.new([:blogs, :main_blog])
#         }
#       }
#     end

#     it 'generates the correct set of selectors' do
#       generator.selectors.should eq(expected_selectors)
#     end

#   end

# end
