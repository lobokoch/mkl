package br.com.kerubin.dsl.mkl.generator

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import static extension br.com.kerubin.dsl.mkl.generator.Utils.*
import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.Slot

class JavaEntityControllerGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		entities.forEach[generateController]
	}
	
	def generateController(Entity entity) {
		val basePakage = serverGenSourceFolder
		val fileName = basePakage + entity.packagePath + '/' + entity.toControllerName + '.java'
		generateFile(fileName, entity.generateEntityController)
	}
	
	def CharSequence generateEntityController(Entity entity) {
		val entityName = entity.toEntityName
		val entityVar = entity.toEntityName.toFirstLower
		val entityDTOName = entity.toEntityDTOName
		val entityDTOVar = entity.toEntityDTOName.toFirstLower
		val entityServiceVar = entity.toServiceName.toFirstLower
		val idVar = entity.id.name.toFirstLower
		val idType = if (entity.id.isEntity) entity.id.asEntity.id.toJavaType else entity.id.toJavaType
		val toDTO = 'convertEntityToDto'
		val toEntity = 'convertDtoToEntity'
		
		'''
		package «entity.package»;
		
		«IF entity.hasAutoComplete»
		import java.util.Collection;
		import org.springframework.web.bind.annotation.RequestParam;
		«ENDIF»
		import java.util.List;
		import java.util.stream.Collectors;
		
		import javax.validation.Valid;
		import org.springframework.beans.factory.annotation.Autowired;
		import org.springframework.web.bind.annotation.RestController;
		import org.springframework.web.bind.annotation.RequestMapping;
		import org.springframework.web.bind.annotation.ResponseStatus;
		import org.springframework.http.ResponseEntity;
		import org.springframework.http.HttpStatus;
		
		import org.springframework.web.bind.annotation.PathVariable;
		import org.springframework.web.bind.annotation.RequestBody;
		import org.springframework.web.bind.annotation.PostMapping;
		import org.springframework.web.bind.annotation.GetMapping;
		import org.springframework.web.bind.annotation.PutMapping;
		import org.springframework.web.bind.annotation.DeleteMapping;
		
		import org.springframework.data.domain.Page;
		import org.springframework.data.domain.Pageable;
		«service.importPageResult»
		
		
		@RestController
		@RequestMapping("entities/«entityDTOVar»")
		public class «entity.toControllerName» {
			
			@Autowired
			private «entity.toServiceName» «entityServiceVar»;
			
			@Autowired
			«entityDTOName»DTOConverter «entityDTOVar»DTOConverter;
			
			@PostMapping
			public ResponseEntity<«entityDTOName»> create(@Valid @RequestBody «entityDTOName» «entityDTOVar») {
				«entityName» «entityVar» = «entityServiceVar».create(«entityDTOVar»DTOConverter.«toEntity»(«entityDTOVar»));
				return ResponseEntity.status(HttpStatus.CREATED).body(«entityDTOVar»DTOConverter.«toDTO»(«entityVar»));
			}
			
			@GetMapping("/{«idVar»}")
			public ResponseEntity<«entityDTOName»> read(@PathVariable «idType» «idVar») {
				try {
					«entityName» «entityVar» = «entityServiceVar».read(«idVar»);
					return ResponseEntity.ok(«entityDTOVar»DTOConverter.«toDTO»(«entityVar»));
				}
				catch(IllegalArgumentException e) {
					return ResponseEntity.notFound().build();
				}
			}
			
			@PutMapping("/{«idVar»}")
			public ResponseEntity<«entityDTOName»> update(@PathVariable «idType» «idVar», @Valid @RequestBody «entityDTOName» «entityDTOVar») {
				try {
					«entityName» «entityVar» = «entityServiceVar».update(«idVar», «entityDTOVar»DTOConverter.«toEntity»(«entityDTOVar»));
					return ResponseEntity.ok(«entityDTOVar»DTOConverter.«toDTO»(«entityVar»));
				}
				catch(IllegalArgumentException e) {
					return ResponseEntity.notFound().build();
				}
			}
			
			@DeleteMapping("/{«idVar»}")
			@ResponseStatus(HttpStatus.NO_CONTENT)
			public void delete(@PathVariable «idType» «idVar») {
				«entityServiceVar».delete(«idVar»);
			}
			
			@GetMapping
			public PageResult<«entityDTOName»> list(«entity.toEntityListFilterClassName» «entity.toEntityListFilterName.toFirstLower», Pageable pageable) {
				Page<«entityName»> page = «entityServiceVar».list(«entity.toEntityListFilterName.toFirstLower», pageable);
				List<«entityDTOName»> content = page.getContent().stream().map(pe -> «entityDTOVar»DTOConverter.«toDTO»(pe)).collect(Collectors.toList());
				PageResult<«entityDTOName»> pageResult = new PageResult<>(content, page.getNumber(), page.getSize(), page.getTotalElements());
				return pageResult;
			}
			
			«IF entity.hasAutoComplete»
			@GetMapping("/autoComplete")
			public Collection<«entity.toAutoCompleteName»> autoComplete(@RequestParam("query") String query) {
				Collection<«entity.toAutoCompleteName»> result = «entityServiceVar».autoComplete(query);
				return result;
			}
			«ENDIF»
			
			«IF entity.hasListFilterMany»
			«entity.slots.filter[it.isListFilterMany].map[generateListFilterAutoComplete].join»
			«ENDIF»
			
			«IF entity.hasSumFields»
			«entity.generateMethodGetContaPagarSumFields»
			«ENDIF»
		}
		'''
	}
	
	def CharSequence generateMethodGetContaPagarSumFields(Entity entity) {
		val sumFieldsName = entity.toEntitySumFieldsName
		val getEntitySumFields = 'get' + sumFieldsName
		val entityServiceVar = entity.toServiceName.toFirstLower
		val listFilterName = entity.toEntityListFilterName
		
		'''
		@GetMapping("/«sumFieldsName.toFirstLower»")
		public «entity.toEntitySumFieldsName» «getEntitySumFields»(«entity.toEntityListFilterClassName» «listFilterName») {
			«sumFieldsName» result = «entityServiceVar».«getEntitySumFields»(«listFilterName»);
			return result;
		}
		'''
	}
	
	def CharSequence generateListFilterAutoComplete(Slot slot) {
		val autoComplateName = slot.toAutoCompleteName
		'''
		
		@GetMapping("/«autoComplateName»")
		public Collection<«autoComplateName.toFirstUpper»> «autoComplateName»(@RequestParam("query") String query) {
			Collection<«autoComplateName.toFirstUpper»> result = «slot.ownerEntity.toServiceName.toFirstLower».«autoComplateName»(query);
			return result;
		}
		'''
	}
	
}