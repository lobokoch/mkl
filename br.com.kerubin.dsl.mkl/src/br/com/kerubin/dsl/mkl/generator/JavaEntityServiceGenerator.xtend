package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity
import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import static extension br.com.kerubin.dsl.mkl.generator.Utils.*

class JavaEntityServiceGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		entities.forEach[generateRepository]
	}
	
	def generateRepository(Entity entity) {
		val basePakage = serverGenSourceFolder
		val fileName = basePakage + entity.packagePath + '/' + entity.toServiceName + '.java'
		generateFile(fileName, entity.generateEntityRepository)
	}
	
	def CharSequence generateEntityRepository(Entity entity) {
		val entityName = entity.toEntityName
		val entityVar = entity.toEntityName.toFirstLower
		val entityDTOName = entity.toEntityDTOName
		val repositoryVar = entity.toRepositoryName.toFirstLower
		val idVar = entity.id.name.toFirstLower
		val idType = entity.id.toJavaType
		val actualEntityVar = 'actual' + entityName
		val getEntityMethod = 'get' + entityName
		
		'''
		package «entity.package»;
		
		import org.springframework.beans.BeanUtils;
		import org.springframework.beans.factory.annotation.Autowired;
		import org.springframework.data.domain.Page;
		import org.springframework.data.domain.Pageable;
		import org.springframework.stereotype.Service;
		
		@Service
		public class «entity.toServiceName» {
			
			@Autowired
			private «entity.toRepositoryName» «repositoryVar»;
			
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
				«repositoryVar».delete(«idVar»);
			}
			
			public Page<«entityName»> list(Pageable pageable) {
				Page<«entityName»> resultPage = «repositoryVar».findAll(pageable);
				return resultPage;
			}
			
			private «entityName» «getEntityMethod»(«idType» «entity.id.name») {
				«entityName» «entityVar» = «repositoryVar».findOne(«idVar»);
				if («entityVar» == null) {
					throw new IllegalArgumentException("«entityDTOName» not found:" + «idVar».toString());
				}
				return «entityVar»;
			}
		}
		'''
	}
	
}