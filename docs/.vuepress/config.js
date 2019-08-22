module.exports = {
  title: "Kubernetes + Flux + Istio + GitLab + Harbor",
  description: "Kubernetes + Flux + Istio + GitLab + Harbor",
  base: '/k8s-flux-istio-gitlab-harbor/',
  head: [
    ['link', { rel: "icon", href: "https://kubernetes.io/images/favicon.png" }]
  ],
  themeConfig: {
    displayAllHeaders: true,
    lastUpdated: true,
    repo: 'ruzickap/k8s-flux-istio-gitlab-harbor',
    docsDir: 'docs',
    editLinks: true,
    logo: 'https://kubernetes.io/images/favicon.png',
    nav: [
      { text: 'Home', link: '/' },
      {
        text: 'Links',
        items: [
          { text: 'Flux', link: 'https://www.weave.works/oss/flux/' },
          { text: 'GitLab', link: 'https://gitlab.com' },
          { text: 'Harbor', link: 'https://goharbor.io' },
        ]
      }
    ],
    sidebar: [
      '/',
      '/part-01/',
      '/part-02/',
      '/part-03/',
      '/part-04/',
    ]
  },
  plugins: [
    ['@vuepress/medium-zoom'],
    ['@vuepress/back-to-top'],
    ['reading-progress'],
    ['smooth-scroll'],
    ['seo']
  ]
}
