package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity
import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import static extension br.com.kerubin.dsl.mkl.generator.Utils.*
import br.com.kerubin.dsl.mkl.model.Slot

class JavaEntityServiceGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		entities.forEach[it |
			generateServiceInterface
			generateServiceInterfaceImpl
		]
	}
	
	def generateServiceInterface(Entity entity) {
		val basePakage = serverGenSourceFolder
		val fileName = basePakage + entity.packagePath + '/' + entity.toServiceName + '.java'
		generateFile(fileName, entity.generateEntityServiceInterface)
	}
	
	def generateServiceInterfaceImpl(Entity entity) {
		val basePakage = serverGenSourceFolder
		val fileName = basePakage + entity.packagePath + '/' + entity.toServiceImplName + '.java'
		generateFile(fileName, entity.generateEntityServiceInterfaceImpl)
	}
	
	def CharSequence generateEntityServiceInterface(Entity entity) {
		val entityName = entity.toEntityName
		val entityVar = entity.toEntityName.toFirstLower
		val idVar = entity.id.name.toFirstLower
		val idType = if (entity.id.isEntity) entity.id.asEntity.id.toJavaType else entity.id.toJavaType
		
		'''
		package «entity.package»;
		
		import org.springframework.data.domain.Page;
		import org.springframework.data.domain.Pageable;
		
		«IF entity.hasAutoComplete»
		import java.util.Collection;
		«ENDIF»
		
		public interface «entity.toServiceName» {
			
			public «entityName» create(«entityName» «entityVar»);
			
			public «entityName» read(«idType» «idVar»);
			
			public «entityName» update(«idType» «idVar», «entityName» «entityVar»);
			
			public void delete(«idType» «idVar»);
			
			public Page<«entityName»> list(«entity.toEntityListFilterName» «entity.toEntityListFilterName.toFirstLower», Pageable pageable);
			
			«IF entity.hasAutoComplete»
			public Collection<«entity.toAutoCompleteName»> autoComplete(String query);
			«ENDIF»
			«IF entity.hasListFilterMany»
			«entity.slots.filter[it.isListFilterMany].map[generateListFilterAutoComplete].join»
			«ENDIF»
		}
		'''
	}
	
	def CharSequence generateListFilterAutoComplete(Slot slot) {
		val autoComplateName = slot.toAutoCompleteName
		'''
		
		public Collection<«autoComplateName.toFirstUpper»> «autoComplateName»(String query);
		'''
	}
	
	def CharSequence generateEntityServiceInterfaceImpl(Entity entity) {
		val entityName = entity.toEntityName
		val entityVar = entity.toEntityName.toFirstLower
		val entityDTOName = entity.toEntityDTOName
		val repositoryVar = entity.toRepositoryName.toFirstLower
		val idVar = entity.id.name.toFirstLower
		val idType = if (entity.id.isEntity) entity.id.asEntity.id.toJavaType else entity.id.toJavaType
		val actualEntityVar = 'actual' + entityName
		val getEntityMethod = 'get' + entityName
		
		'''
		package «entity.package»;
		
		import org.springframework.beans.BeanUtils;
		import org.springframework.beans.factory.annotation.Autowired;
		import org.springframework.data.domain.Page;
		import org.springframework.data.domain.Pageable;
		import org.springframework.stereotype.Service;
		
		import com.querydsl.core.types.Predicate;
		
		import java.util.Optional;
		«IF entity.hasAutoComplete»
		import java.util.Collection;
		«ENDIF»
		
		@Service
		public class «entity.toServiceImplName» implements «entity.toServiceName» {
			
			@Autowired
			private «entity.toRepositoryName» «repositoryVar»;
			
			@Autowired
			private «entity.toEntityListFilterPredicateName» «entity.toEntityListFilterPredicateName.toFirstLower»;
			
			public «entityName» create(«entityName» «entityVar») {
				return «repositoryVar».save(«entityVar»);
			}
			
			public «entityName» read(«idType» «idVar») {
				return «getEntityMethod»(«idVar»);
			}
			
			public «entityName» update(«idType» «idVar», «entityName» «entityVar») {
				«entityName» «actualEntityVar» = «getEntityMethod»(«idVar»);
				BeanUtils.copyProperties(«entityVar», «actualEntityVar», "«entity.id.name»");
				return «repositoryVar».save(«actualEntityVar»);
			}
			
			public void delete(«idType» «idVar») {
				«repositoryVar».deleteById(«idVar»);
			}
			
			public Page<«entityName»> list(«entity.toEntityListFilterName» «entity.toEntityListFilterName.toFirstLower», Pageable pageable) {
				Predicate predicate = «entity.toEntityListFilterPredicateName.toFirstLower».mountAndGetPredicate(«entity.toEntityListFilterName.toFirstLower»);
				
				Page<«entityName»> resultPage = «repositoryVar».findAll(predicate, pageable);
				return resultPage;
			}
			
			private «entityName» «getEntityMethod»(«idType» «entity.id.name») {
				Optional<«entityName»> «entityVar» = «repositoryVar».findById(«idVar»);
				if (!«entityVar».isPresent()) {
					throw new IllegalArgumentException("«entityDTOName» not found:" + «idVar».toString());
				}
				return «entityVar».get();
			}
			
			«IF entity.hasAutoComplete»
			public Collection<«entity.toAutoCompleteName»> autoComplete(String query) {
				Collection<«entity.toAutoCompleteName»> result = «repositoryVar».autoComplete(query);
				return result;
			}
			«ENDIF»
			«IF entity.hasListFilterMany»
			«entity.slots.filter[it.isListFilterMany].map[generateListFilterAutoCompleteImpl].join»
			«ENDIF»
		}
		'''
	}
	
	def CharSequence generateListFilterAutoCompleteImpl(Slot slot) {
		val autoComplateName = slot.toAutoCompleteName
		val repositoryVar = slot.ownerEntity.toRepositoryName.toFirstLower
		
		'''
		
		public Collection<«autoComplateName.toFirstUpper»> «autoComplateName»(String query) {
			Collection<«autoComplateName.toFirstUpper»> result = «repositoryVar».«autoComplateName»(query);
			return result;
		}
		'''
	}
	
}